-- Debugger (nvim-dap) state. Everything is optional: with no DAP installed the
-- segment simply never appears.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}
local registered = false

local function count_breakpoints()
  local ok, bps = pcall(function()
    return require("dap.breakpoints").get()
  end)
  if not ok or not bps then
    return 0
  end
  local n = 0
  for _, list in pairs(bps) do
    n = n + #list
  end
  return n
end

function M.poll()
  local dap = package.loaded["dap"]
  if not dap then
    return
  end
  local session = dap.session()
  state.dap.active = session ~= nil
  state.dap.breakpoints = count_breakpoints()
  if session then
    local ok, st = pcall(dap.status)
    state.dap.status = (ok and st and st ~= "") and st:upper() or "ATTACHED"
  else
    state.dap.status = "STANDBY"
  end
end

local function register()
  local dap = package.loaded["dap"]
  if not dap or registered then
    return
  end
  registered = true
  local function on(ev, fn)
    dap.listeners.after[ev]["lcars"] = function(...)
      fn(...)
      M.poll()
      util.redrawstatus()
    end
  end
  on("event_initialized", function()
    state.dap.active = true
    require("lcars.notifications").event("dap-start", "DEBUGGING SUBSYSTEM ENGAGED", { title = "TACTICAL" })
  end)
  on("event_stopped", function()
    state.dap.status = "PAUSED"
  end)
  on("event_continued", function()
    state.dap.status = "RUNNING"
  end)
  local function off(ev)
    dap.listeners.before[ev]["lcars"] = function()
      state.dap.active = false
      state.dap.status = "STANDBY"
      require("lcars.notifications").event("dap-stop", "DEBUGGING SUBSYSTEM DISENGAGED", { title = "TACTICAL" })
      vim.schedule(util.redrawstatus)
    end
  end
  off("event_terminated")
  off("event_exited")
  M.poll()
end

local function unregister()
  local dap = package.loaded["dap"]
  if dap and registered then
    for _, ev in ipairs({ "event_initialized", "event_stopped", "event_continued" }) do
      dap.listeners.after[ev]["lcars"] = nil
    end
    for _, ev in ipairs({ "event_terminated", "event_exited" }) do
      dap.listeners.before[ev]["lcars"] = nil
    end
  end
  registered = false
end

---@param group integer
function M.setup(group)
  state.dap.available = util.has_plugin("nvim-dap")
  if not state.dap.available then
    return
  end
  register()
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = function(ev)
      if ev.data == "nvim-dap" then
        register()
      end
    end,
  })
end

function M.teardown()
  unregister()
  state.dap.active = false
  state.dap.status = "STANDBY"
end

return M
