-- Test status. Prefers neotest when present; otherwise reads pytest's own
-- cache (.pytest_cache/v/cache/{nodeids,lastfailed}) written by the last run,
-- so results from a terminal `pytest` show up too. Never runs tests itself.
local state = require("lcars.state")
local util = require("lcars.util")

local uv = vim.uv or vim.loop
local M = {}

local watcher = nil ---@type uv.uv_fs_event_t?
local watched_dir = nil
local known = false

local function announce()
  local t = state.tests
  if not known then
    known = true
    return
  end
  if t.status == "PASS" then
    require("lcars.notifications").event(
      "tests-pass",
      string.format("VALIDATION SEQUENCE COMPLETE · %d/%d", t.passed or 0, t.total or 0),
      { cooldown = 2 }
    )
  elseif t.status == "FAIL" then
    require("lcars.notifications").event(
      "tests-fail",
      string.format("VALIDATION FAILURE · %d FAILED", t.failed or 0),
      { level = vim.log.levels.WARN, cooldown = 2 }
    )
  end
end

local function from_neotest()
  local neotest = package.loaded["neotest"]
  if not neotest or not neotest.state then
    return false
  end
  local ok, ids = pcall(neotest.state.adapter_ids)
  if not ok or not ids or #ids == 0 then
    return false
  end
  local total, passed, failed, running = 0, 0, 0, 0
  for _, id in ipairs(ids) do
    local ok2, c = pcall(neotest.state.status_counts, id)
    if ok2 and c then
      total = total + (c.total or 0)
      passed = passed + (c.passed or 0)
      failed = failed + (c.failed or 0)
      running = running + (c.running or 0)
    end
  end
  if total == 0 then
    return false
  end
  local prev = state.tests.status
  state.tests.source = "neotest"
  state.tests.total, state.tests.passed, state.tests.failed = total, passed, failed
  if running > 0 then
    state.tests.status = "RUNNING"
  elseif failed > 0 then
    state.tests.status = "FAIL"
  else
    state.tests.status = "PASS"
  end
  if prev ~= state.tests.status and state.tests.status ~= "RUNNING" then
    announce()
  end
  return true
end

local function from_pytest_cache(root)
  local dir = root .. "/.pytest_cache/v/cache"
  if not util.exists(dir .. "/nodeids") then
    if state.tests.source == "pytest-cache" or state.tests.source == nil then
      state.tests.status = "UNKNOWN"
      state.tests.total, state.tests.passed, state.tests.failed = nil, nil, nil
      state.tests.source = nil
    end
    return
  end
  util.read_file(dir .. "/nodeids", function(nodeids)
    local ok, list = pcall(vim.json.decode, nodeids or "")
    local total = (ok and type(list) == "table") and #list or 0
    util.read_file(dir .. "/lastfailed", function(lf)
      local failed = 0
      if lf then
        local ok2, map = pcall(vim.json.decode, lf)
        if ok2 and type(map) == "table" then
          for _ in pairs(map) do
            failed = failed + 1
          end
        end
      end
      local prev, prev_failed = state.tests.status, state.tests.failed
      state.tests.source = "pytest-cache"
      state.tests.total = total
      state.tests.failed = failed
      state.tests.passed = math.max(0, total - failed)
      state.tests.status = failed > 0 and "FAIL" or "PASS"
      if prev ~= state.tests.status or prev_failed ~= failed then
        announce()
      end
      util.redrawstatus()
    end)
  end)
end

local function do_refresh()
  if not state.enabled then
    return
  end
  if from_neotest() then
    util.redrawstatus()
    return
  end
  from_pytest_cache(util.root())
end

M.refresh = util.throttle(1500, do_refresh)

local debounced = util.debounce(600, function()
  M.refresh()
end)

local function stop_watch()
  if watcher then
    pcall(function()
      watcher:stop()
      if not watcher:is_closing() then
        watcher:close()
      end
    end)
  end
  watcher, watched_dir = nil, nil
end

--- Watch the pytest cache directory so runs from another terminal show up live.
local function watch(root)
  local dir = root .. "/.pytest_cache/v/cache"
  if watched_dir == dir then
    return
  end
  stop_watch()
  if not util.exists(dir) then
    return
  end
  local h = uv.new_fs_event()
  if not h then
    return
  end
  local ok = h:start(dir, {}, function()
    vim.schedule(debounced)
  end)
  if ok == 0 then
    watcher, watched_dir = h, dir
  else
    pcall(h.close, h)
  end
end

---@param group integer
function M.setup(group)
  known = false
  vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "TermClose" }, {
    group = group,
    callback = function()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      known = false
      watch(util.root())
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      local root = util.root()
      if root .. "/.pytest_cache/v/cache" ~= watched_dir then
        watch(root)
        M.refresh()
      end
    end,
  })
  watch(util.root())
  do_refresh()
end

function M.teardown()
  stop_watch()
  known = false
end

--- Compact label: "148✓" / "2✗ 146✓" / nil when unknown
function M.label()
  local t = state.tests
  if t.status == "UNKNOWN" then
    return nil
  end
  if t.status == "RUNNING" then
    return "RUNNING"
  end
  if t.status == "FAIL" then
    return string.format("%d✗ %d✓", t.failed or 0, t.passed or 0)
  end
  return string.format("%d✓", t.passed or t.total or 0)
end

return M
