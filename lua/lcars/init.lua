-- LCARS: public API and lifecycle (enable / disable / toggle / reload).
--
--   local lcars = require("lcars")
--   lcars.setup(opts)      -- called from lua/plugins/lcars.lua
--   lcars.enable() / lcars.disable() / lcars.toggle()
--   lcars.animations.enable() / .disable() / .toggle()
--   lcars.red_alert(true|false|nil)
--   lcars.status() / lcars.center() / lcars.refresh() / lcars.reload()
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

M.defaults = {
  enabled = false, -- start with LCARS on (ignores persistence)
  persist_mode = false, -- remember on/off across restarts
  fallback_colorscheme = nil, -- restore target if the previous theme can't be detected
  transparent = true, -- keep the terminal's own background (glass)
  dim_inactive = true, -- muted foreground in inactive windows
  cursor = true, -- steady LCARS cursor while enabled
  terminal_colors = true,

  animations = {
    enabled = true,
    interval = 750, -- ms per tick
    pause_unfocused = true,
  },

  dashboard = true,
  statusline = true,
  winbar = true,
  notifications = true,
  picker = true,
  diagnostics = true,
  bufferline = true,

  python = true,
  python_always = false, -- show the PYTHON segment in every filetype
  git = true,
  tests = true,
  dap = true,
  ai = true,

  heartbeat = true, -- LCARS ● and the rotating data readout
  data_cascade = true, -- dashboard cascade rows
  stardate = true,
  system_messages = true, -- contextual "LANGUAGE ANALYSIS LINK ESTABLISHED" style notices

  red_alert = {
    enabled = true,
    automatic = false, -- engage automatically when errors >= threshold
    threshold = 1,
  },
}

local user_opts = {}

local function persist_path()
  return vim.fn.stdpath("state") .. "/lcars.json"
end

local function read_persisted()
  local f = io.open(persist_path(), "r")
  if not f then
    return nil
  end
  local ok, data = pcall(vim.json.decode, f:read("*a") or "")
  f:close()
  return ok and type(data) == "table" and data or nil
end

local function write_persisted(enabled)
  if not state.config.persist_mode then
    return
  end
  local f = io.open(persist_path(), "w")
  if f then
    f:write(vim.json.encode({ enabled = enabled }))
    f:close()
  end
end

-- Lifecycle -------------------------------------------------------------------

local function modules_enable(group)
  local c = state.config
  require("lcars.events").setup(group)
  if c.statusline ~= false then
    require("lcars.statusline").setup(group)
  end
  if c.winbar ~= false then
    require("lcars.winbar").setup(group)
  end
  if c.python ~= false then
    require("lcars.python").setup(group)
  end
  if c.git ~= false then
    require("lcars.git").setup(group)
  end
  require("lcars.lsp").setup(group)
  if c.tests ~= false then
    require("lcars.tests").setup(group)
  end
  if c.dap ~= false then
    require("lcars.dap").setup(group)
  end
  if c.ai ~= false then
    require("lcars.ai").setup(group)
  end
  if c.bufferline ~= false then
    require("lcars.bufferline").enable()
  end
  if c.picker ~= false then
    require("lcars.picker").enable()
  end
  if c.dashboard ~= false then
    require("lcars.dashboard").setup(group)
  end
  require("lcars.animations").setup(group)
end

local function modules_disable()
  for _, name in ipairs({
    "animations",
    "dashboard",
    "tests",
    "dap",
    "ai",
    "git",
    "python",
    "lsp",
    "winbar",
    "statusline",
    "events",
    "system",
  }) do
    local ok, mod = pcall(require, "lcars." .. name)
    if ok and mod.teardown then
      pcall(mod.teardown)
    end
  end
  pcall(require("lcars.picker").disable)
  pcall(require("lcars.bufferline").disable)
end

---@param opts? {silent?: boolean, startup?: boolean}
function M.enable(opts)
  opts = opts or {}
  if state.enabled then
    return
  end
  -- remember where we came from
  local prev = vim.g.colors_name
  if not prev or prev == "" or prev == "lcars" then
    prev = state.config.fallback_colorscheme
      or (package.loaded["lazyvim"] and type(LazyVim.config.colorscheme) == "string" and LazyVim.config.colorscheme)
      or "default"
  end
  state.prev.colorscheme = prev
  state.prev.guicursor = vim.o.guicursor
  state.prev.fillchars = vim.o.fillchars

  state._switching = true
  local ok, err = pcall(vim.cmd.colorscheme, "lcars")
  state._switching = false
  if not ok then
    vim.notify("LCARS colorscheme failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  state.enabled = true
  state.tick = 0
  local group = util.augroup()
  local ok2, err2 = pcall(modules_enable, group)
  if not ok2 then
    vim.notify("LCARS subsystem fault: " .. tostring(err2), vim.log.levels.ERROR, { title = "LCARS" })
  end

  if state.config.cursor ~= false then
    local gc = vim.o.guicursor
    if gc == "" then
      gc = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
    end
    vim.o.guicursor = gc .. ",a:blinkon0"
  end
  vim.opt.fillchars:append({ eob = " " })

  write_persisted(true)
  vim.schedule(function()
    util.redrawstatus()
    pcall(require("lcars.dashboard").update)
    if not opts.silent and not opts.startup then
      require("lcars.notifications").event("lcars-on", "LCARS INTERFACE ONLINE", { cooldown = 0 })
    end
  end)
end

---@param opts? {silent?: boolean}
function M.disable(opts)
  opts = opts or {}
  if not state.enabled then
    return
  end
  if state.red_alert then
    state.red_alert = false
  end
  modules_disable()
  util.del_augroup()
  state.enabled = false
  state.animating = false

  if state.prev.guicursor ~= nil then
    vim.o.guicursor = state.prev.guicursor
  end
  if state.prev.fillchars ~= nil then
    vim.o.fillchars = state.prev.fillchars
  end

  local target = state.prev.colorscheme or state.config.fallback_colorscheme or "default"
  state._switching = true
  local ok = pcall(vim.cmd.colorscheme, target)
  if not ok and state.config.fallback_colorscheme and target ~= state.config.fallback_colorscheme then
    ok = pcall(vim.cmd.colorscheme, state.config.fallback_colorscheme)
  end
  if not ok then
    pcall(vim.cmd.colorscheme, "default")
  end
  state._switching = false

  require("lcars.notifications").reset()
  write_persisted(false)
  vim.schedule(function()
    pcall(vim.cmd.redrawstatus)
    pcall(require("lcars.dashboard").update)
    if not opts.silent then
      vim.notify("LCARS INTERFACE OFFLINE", vim.log.levels.INFO, { title = "LCARS" })
    end
  end)
end

function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
  return state.enabled
end

---@param on? boolean nil toggles
function M.red_alert(on)
  if not state.enabled then
    vim.notify("LCARS INTERFACE OFFLINE · RED ALERT UNAVAILABLE", vim.log.levels.WARN, { title = "LCARS" })
    return false
  end
  if state.config.red_alert and state.config.red_alert.enabled == false then
    return false
  end
  if on == nil then
    on = not state.red_alert
  end
  if on == state.red_alert then
    return on
  end
  state.red_alert = on
  require("lcars.theme").apply_alert(on)
  util.redrawstatus()
  pcall(require("lcars.dashboard").update)
  if on then
    require("lcars.notifications").event(
      "red-alert",
      "RED ALERT · ALL STATIONS",
      { level = vim.log.levels.ERROR, title = "TACTICAL", cooldown = 0 }
    )
  else
    require("lcars.notifications").event(
      "red-alert-off",
      "ALERT CANCELLED · CONDITION NORMAL",
      { title = "TACTICAL", cooldown = 0 }
    )
  end
  return on
end

M.animations = setmetatable({}, {
  __index = function(_, k)
    return require("lcars.animations")[k]
  end,
})

function M.status()
  require("lcars.system").open()
end

function M.center()
  require("lcars.center").open()
end

--- Force-refresh every collector.
function M.refresh()
  if not state.enabled then
    return
  end
  pcall(function()
    require("lcars.python").refresh(true)
  end)
  pcall(function()
    require("lcars.git").refresh()
  end)
  pcall(function()
    require("lcars.tests").refresh()
  end)
  pcall(function()
    require("lcars.lsp").update_clients()
  end)
  pcall(function()
    require("lcars.lsp").update_diag()
  end)
  pcall(function()
    require("lcars.ai").poll()
  end)
  pcall(function()
    require("lcars.dap").poll()
  end)
  util.redrawstatus()
end

--- Reload every LCARS module (development aid). Preserves on/off state and uptime.
function M.reload()
  local was = state.enabled
  local started = state.started
  local ids = state.ids
  if was then
    M.disable({ silent = true })
  end
  for name in pairs(package.loaded) do
    if name == "lcars" or name:sub(1, 6) == "lcars." then
      package.loaded[name] = nil
    end
  end
  local fresh = require("lcars")
  fresh.setup(vim.deepcopy(user_opts), { reload = true })
  local st = require("lcars.state")
  st.started = started
  st.ids = ids
  if was then
    fresh.enable({ silent = true })
  end
  vim.notify("LCARS MODULES RELOADED", vim.log.levels.INFO, { title = "LCARS" })
end

function M.is_enabled()
  return state.enabled
end

---@param opts? table
---@param internal? {reload?: boolean}
function M.setup(opts, internal)
  internal = internal or {}
  user_opts = vim.deepcopy(opts or {})
  state.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  if not state.ids or not state.ids.sys then
    require("lcars.system").generate_ids()
  end
  require("lcars.commands").setup()
  require("lcars.keymaps").setup()

  if internal.reload then
    return
  end
  local want = state.config.enabled
  if not want and state.config.persist_mode then
    local p = read_persisted()
    want = p and p.enabled == true
  end
  if want then
    M.enable({ startup = true })
  end
end

return M
