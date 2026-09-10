-- LCARS startup screen built on Snacks dashboard (already provided by LazyVim).
-- `sections_dispatch` is installed at plugin-spec time and decides per render
-- whether to show the LCARS layout or the stock one, so toggling is instant.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local DEFAULT_SECTIONS = {
  { section = "header" },
  { section = "keys", gap = 1, padding = 1 },
  { section = "startup" },
}

local BOOT = {
  "INITIALIZING LCARS INTERFACE",
  "LOADING DEVELOPMENT SUBSYSTEMS",
  "ESTABLISHING LANGUAGE SERVER LINK",
  "SCANNING PROJECT DATABASE",
  "INITIALIZING GIT TELEMETRY",
  "CONNECTING AI SUBSYSTEM",
  "SYSTEM READY",
}

local WIDTH = 60
local cascade = {} ---@type string[]
local boot_timer = util.timer()

local function rand_cascade()
  local rows = {}
  for r = 1, 2 do
    local cells = {}
    for _ = 1, 4 do
      cells[#cells + 1] = string.format("%03d %02d %03d", math.random(0, 999), math.random(0, 99), math.random(0, 999))
    end
    rows[r] = table.concat(cells, "   ")
  end
  cascade = rows
end

local function pad(text, width)
  local w = util.width(text)
  if w >= width then
    return text
  end
  return text .. string.rep(" ", width - w)
end

--- A status row with a coloured LCARS block on the left.
local function row(color_hl, label, value, value_hl)
  local left = "  " .. label
  local right = value
  local fill = WIDTH - 4 - util.width(left) - util.width(right)
  return {
    text = {
      { "██", color_hl },
      { pad(left, util.width(left) + math.max(1, fill)), "LcarsDashLabel" },
      { right, value_hl },
      { " ", "LcarsDashLabel" },
    },
  }
end

local function rail(hl, ch)
  return { text = { { string.rep(ch or "━", WIDTH), hl or "LcarsDashBar" } } }
end

local function header_items()
  local s = state
  local boot_msg = BOOT[math.min(#BOOT, math.max(1, s.boot.phase))] or BOOT[#BOOT]
  if s.boot.done then
    boot_msg = BOOT[#BOOT]
  end
  local bars = math.min(#BOOT, math.max(1, s.boot.phase))
  local prog = string.rep("▰", bars) .. string.rep("▱", #BOOT - bars)
  local sys = string.format("SYS %03d", s.ids.sys or 0)

  local title_l = " LCARS " .. (s.ids.lcars or 47) .. " "
  local title_m = " COMPUTER ACCESS "
  local gap = WIDTH - util.width(title_l) - util.width(title_m) - util.width(sys) - 3
  return {
    {
      text = {
        { title_l, s.red_alert and "LcarsAlertBlock" or "LcarsDashTitle" },
        { " ", "LcarsDashLabel" },
        { title_m, "LcarsBlockLilac" },
        { string.rep(" ", math.max(1, gap)), "LcarsDashLabel" },
        { " " .. sys .. " ", "LcarsBlockGray" },
      },
    },
    rail("LcarsDashBar"),
    {
      text = {
        { "U.S.S. VOYAGER DEVELOPMENT SYSTEM", "LcarsDashSubtitle" },
        { string.rep(" ", math.max(1, WIDTH - 33 - 18)), "LcarsDashLabel" },
        { pad("STARDATE " .. util.stardate(), 18), "LcarsDashId" },
      },
    },
    {
      text = {
        { pad(boot_msg, WIDTH - #prog - 1), s.boot.done and "LcarsDashOnline" or "LcarsDashBoot" },
        { prog, s.boot.done and "LcarsDashOnline" or "LcarsDashBar3" },
      },
      padding = 1,
    },
  }
end

local function status_items()
  local s = state
  local lsp = s.lsp.clients[1]
  local ai_name, ai_status = require("lcars.ai").label()
  local py = s.python
  local git = require("lcars.git")
  local branch = git.branch()
  local tests = s.tests.status

  local function on(v, ok_text, dim_text)
    if v then
      return ok_text, "LcarsDashOnline"
    end
    return dim_text, "LcarsDashOffline"
  end

  local items = {
    { text = { { "SYSTEM STATUS", "LcarsDashSubtitle" } } },
    row(
      "LcarsDashBar",
      "LCARS INTERFACE",
      s.red_alert and "RED ALERT" or "ONLINE",
      s.red_alert and "LcarsDashAlert" or "LcarsDashOnline"
    ),
    row("LcarsDashBar", "NEOVIM " .. require("lcars.system").nvim_version(), "ONLINE", "LcarsDashOnline"),
    row(
      "LcarsDashBar3",
      "PYTHON " .. (py.version or ""),
      on(py.exe, py.venv and ("READY · " .. py.venv:upper()) or "READY", "NOT FOUND")
    ),
    row(
      "LcarsDashBar3",
      "LANGUAGE ANALYSIS",
      lsp and lsp:upper() .. " ●" or "STANDBY",
      lsp and "LcarsDashOnline" or "LcarsDashStandby"
    ),
    row(
      "LcarsDashBar2",
      "GIT TELEMETRY",
      branch and branch:upper() or "NO REPOSITORY",
      branch and "LcarsDashOnline" or "LcarsDashOffline"
    ),
    row(
      "LcarsDashBar2",
      "VALIDATION",
      tests == "UNKNOWN" and "NO DATA" or (require("lcars.tests").label() or tests),
      tests == "PASS" and "LcarsDashOnline" or (tests == "FAIL" and "LcarsDashAlert" or "LcarsDashOffline")
    ),
    row(
      "LcarsDashBar4",
      "AI ASSISTANCE",
      ai_name and (ai_name .. " " .. ai_status) or "OFFLINE",
      (ai_name and ai_status ~= "OFFLINE") and "LcarsDashOnline" or "LcarsDashOffline"
    ),
    row(
      "LcarsDashBar4",
      "DEBUGGER",
      s.dap.available and s.dap.status or "NOT INSTALLED",
      s.dap.available and "LcarsDashStandby" or "LcarsDashOffline"
    ),
  }
  items[#items].padding = 1
  return items
end

local function cascade_items()
  if state.config.data_cascade == false then
    return {}
  end
  if #cascade == 0 then
    rand_cascade()
  end
  local items = {}
  for i, line in ipairs(cascade) do
    items[#items + 1] = { text = { { pad(line, WIDTH), i % 2 == 0 and "LcarsDashCascade" or "LcarsDashCascadeHi" } } }
  end
  items[#items].padding = 1
  return items
end

local function key_items()
  local has_session = false
  pcall(function()
    has_session = require("persistence").current and util.exists(require("persistence").current()) or false
  end)
  local keys = {
    { key = "1", icon = "██", desc = "RECENT FILES", action = ":lua Snacks.dashboard.pick('oldfiles')" },
    { key = "2", icon = "██", desc = "SEARCH FILES", action = ":lua Snacks.dashboard.pick('files')" },
    { key = "3", icon = "██", desc = "SEARCH TEXT", action = ":lua Snacks.dashboard.pick('live_grep')" },
    { key = "4", icon = "██", desc = "PROJECTS", action = ":lua Snacks.picker.projects()" },
    {
      key = "5",
      icon = "██",
      desc = "GIT STATUS",
      action = ":lua Snacks.picker.git_status()",
      enabled = state.git.available,
    },
    { key = "6", icon = "██", desc = "RESTORE SESSION", section = "session", enabled = has_session },
    { key = "7", icon = "██", desc = "SYSTEM STATUS", action = ":LCARSStatus" },
    { key = "8", icon = "██", desc = "LCARS CONTROL CENTER", action = ":LCARS" },
    { key = "l", icon = "██", desc = "PLUGIN MANAGER", action = ":Lazy" },
    {
      key = "c",
      icon = "██",
      desc = "CONFIGURATION",
      action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
    },
    { key = "q", icon = "██", desc = "TERMINATE SESSION", action = ":qa" },
  }
  local out = {}
  for _, k in ipairs(keys) do
    if k.enabled ~= false then
      local key_hl = k.key:match("%d") and "LcarsBlockAmber" or "LcarsBlockLilac"
      k.text = {
        { " " .. k.key .. " ", key_hl },
        { "  " .. k.desc, "LcarsDashLabel" },
      }
      k.icon, k.desc = nil, nil
      out[#out + 1] = k
    end
  end
  return out
end

local function footer_items()
  local ok, lazy = pcall(require, "lazy")
  local stats = ok and lazy.stats() or { loaded = 0, count = 0, startuptime = 0 }
  local ms = math.floor((stats.startuptime or 0) * 100 + 0.5) / 100
  local text = string.format(
    "%d/%d SUBSYSTEMS LOADED · %sms · UP %s",
    stats.loaded,
    stats.count,
    ms,
    util.fmt_duration(state.uptime())
  )
  return {
    rail("LcarsDashBar"),
    {
      text = {
        { " LCARS " .. (state.ids.lcars or 47) .. " ", "LcarsDashTitle" },
        { " " .. pad(text, WIDTH - 12), "LcarsDashId" },
      },
    },
  }
end

--- Full LCARS section list (called on every dashboard render).
function M.sections()
  local out = {}
  vim.list_extend(out, header_items())
  vim.list_extend(out, status_items())
  vim.list_extend(out, cascade_items())
  out[#out + 1] = { text = { { "PROJECT DATABASE", "LcarsDashSubtitle" } } }
  out[#out + 1] = { section = "keys", gap = 0, padding = 1 }
  out[#out + 1] = { text = { { "RECENT RECORDS", "LcarsDashSubtitle" } } }
  out[#out + 1] = { section = "recent_files", limit = 5, indent = 2, padding = 1, cwd = false }
  vim.list_extend(out, footer_items())
  return out
end

--- Installed as opts.dashboard.sections in the Snacks plugin spec.
function M.sections_dispatch(dash)
  if state.enabled and state.config.dashboard ~= false then
    -- keys section reads dash.opts.preset.keys; swap in LCARS keys per render
    if dash and dash.opts and dash.opts.preset then
      if not dash.opts.preset._lcars_original then
        dash.opts.preset._lcars_original = dash.opts.preset.keys
      end
      dash.opts.preset.keys = key_items()
    end
    return M.sections()
  end
  if dash and dash.opts and dash.opts.preset and dash.opts.preset._lcars_original then
    dash.opts.preset.keys = dash.opts.preset._lcars_original
    dash.opts.preset._lcars_original = nil
  end
  return vim.deepcopy(DEFAULT_SECTIONS)
end

function M.visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then
      return true
    end
  end
  return false
end

function M.update()
  if not (package.loaded["snacks"] and Snacks.dashboard) then
    return
  end
  if M.visible() then
    pcall(Snacks.dashboard.update)
  end
end

M.refresh = util.debounce(200, M.update)

local function boot()
  if state.boot.done or boot_timer:running() then
    return
  end
  state.boot.phase = 1
  local function step()
    if not state.enabled then
      state.boot.done = true
      return
    end
    if state.boot.phase >= #BOOT then
      state.boot.done = true
      M.update()
      return
    end
    state.boot.phase = state.boot.phase + 1
    M.update()
    boot_timer:start(140, step, false)
  end
  boot_timer:start(140, step, false)
end

function M.on_tick()
  if state.config.data_cascade == false or not state.boot.done then
    return
  end
  if M.visible() then
    rand_cascade()
    M.update()
  end
end

---@param group integer
function M.setup(group)
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardOpened",
    callback = function()
      if state.config.dashboard ~= false then
        boot()
      end
    end,
  })
  if M.visible() then
    boot()
    M.update()
  end
end

function M.teardown()
  boot_timer:stop()
  state.boot.done = true
  M.update()
end

return M
