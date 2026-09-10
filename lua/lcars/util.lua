-- Small helpers shared by LCARS modules: timers, augroups, highlight strings,
-- throttling and defensive requires.
local M = {}

local uv = vim.uv or vim.loop

M.AUGROUP = "lcars"

---@param name? string
---@return integer
function M.augroup(name)
  return vim.api.nvim_create_augroup(name and ("lcars_" .. name) or M.AUGROUP, { clear = true })
end

---@param name? string
function M.del_augroup(name)
  pcall(vim.api.nvim_del_augroup_by_name, name and ("lcars_" .. name) or M.AUGROUP)
end

--- Safe require: returns module or nil, never throws.
---@generic T
---@param mod string
---@return T?
function M.try_require(mod)
  local ok, m = pcall(require, mod)
  if ok then
    return m
  end
  return nil
end

---@param name string plugin name as known to lazy.nvim
function M.has_plugin(name)
  local ok, cfg = pcall(require, "lazy.core.config")
  return ok and cfg.spec and cfg.spec.plugins[name] ~= nil
end

---@param name string
function M.plugin_loaded(name)
  local ok, cfg = pcall(require, "lazy.core.config")
  local p = ok and cfg.spec and cfg.spec.plugins[name]
  return p and p._ and p._.loaded ~= nil
end

-- Timers ------------------------------------------------------------------

---@class lcars.Timer
---@field handle uv.uv_timer_t?
local Timer = {}
Timer.__index = Timer

---@param interval number ms
---@param fn fun()
---@param repeat_ boolean
function Timer:start(interval, fn, repeat_)
  self:stop()
  local t = uv.new_timer()
  if not t then
    return
  end
  self.handle = t
  t:start(interval, repeat_ and interval or 0, function()
    if not repeat_ then
      self:stop()
    end
    vim.schedule(function()
      local ok, err = pcall(fn)
      if not ok then
        vim.schedule(function()
          vim.notify("LCARS timer error: " .. tostring(err), vim.log.levels.ERROR)
        end)
        self:stop()
      end
    end)
  end)
end

function Timer:stop()
  local t = self.handle
  self.handle = nil
  if t and not t:is_closing() then
    t:stop()
    t:close()
  end
end

function Timer:running()
  return self.handle ~= nil
end

function M.timer()
  return setmetatable({}, Timer)
end

--- Throttle an async job: at most one run per `ms`, trailing call coalesced.
---@param ms number
---@param fn fun()
function M.throttle(ms, fn)
  local last, pending, timer = 0, false, M.timer()
  return function()
    local now = uv.now()
    if now - last >= ms then
      last = now
      fn()
    elseif not pending then
      pending = true
      timer:start(ms - (now - last), function()
        pending = false
        last = uv.now()
        fn()
      end, false)
    end
  end
end

--- Debounce
---@param ms number
---@param fn fun()
function M.debounce(ms, fn)
  local timer = M.timer()
  return function()
    timer:start(ms, fn, false)
  end
end

-- Statusline string helpers -----------------------------------------------

---@param hl string
---@param text string
function M.hl(hl, text)
  return "%#" .. hl .. "#" .. text
end

--- Escape % for statusline embedding.
function M.esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

function M.width(s)
  return vim.fn.strdisplaywidth(s)
end

--- Async process helper (never blocks). cb(code, stdout).
---@param cmd string[]
---@param opts? {cwd?: string}
---@param cb fun(code:integer, out:string)
function M.system(cmd, opts, cb)
  opts = opts or {}
  local ok = pcall(vim.system, cmd, { cwd = opts.cwd, text = true, timeout = 8000 }, function(res)
    vim.schedule(function()
      cb(res.code, res.stdout or "")
    end)
  end)
  if not ok then
    cb(-1, "")
  end
end

--- Async read of a small file. cb(content|nil)
---@param path string
---@param cb fun(content:string?)
function M.read_file(path, cb)
  uv.fs_open(path, "r", 438, function(err, fd)
    if err or not fd then
      return vim.schedule(function()
        cb(nil)
      end)
    end
    uv.fs_fstat(fd, function(_, stat)
      local size = stat and stat.size or 0
      if size > 1024 * 1024 then
        uv.fs_close(fd)
        return vim.schedule(function()
          cb(nil)
        end)
      end
      uv.fs_read(fd, size, 0, function(_, data)
        uv.fs_close(fd)
        vim.schedule(function()
          cb(data)
        end)
      end)
    end)
  end)
end

function M.exists(path)
  return path and uv.fs_stat(path) ~= nil
end

--- Current project root (LazyVim aware).
function M.root()
  local ok, r = pcall(function()
    return LazyVim.root()
  end)
  if ok and r and r ~= "" then
    return r
  end
  return uv.cwd()
end

function M.project_name(root)
  root = root or M.root()
  return vim.fn.fnamemodify(root, ":t")
end

function M.redrawstatus()
  if vim.api.nvim_get_mode().mode:sub(1, 1) ~= "c" then
    pcall(vim.cmd.redrawstatus)
  end
end

--- Format seconds as HH:MM or HH:MM:SS
function M.fmt_duration(secs, with_seconds)
  local h = math.floor(secs / 3600)
  local m = math.floor((secs % 3600) / 60)
  local s = secs % 60
  if with_seconds then
    return string.format("%02d:%02d:%02d", h, m, s)
  end
  return string.format("%02d:%02d", h, m)
end

--- Decorative stardate (Voyager-era numbering).
function M.stardate()
  local d = os.date("*t")
  local yday = tonumber(os.date("%j")) or 1
  local frac = (yday - 1 + (d.hour * 3600 + d.min * 60) / 86400) / 365.25
  return string.format("%.1f", 1000 * (d.year - 1978) + frac * 1000)
end

--- Is a window a normal editing window (not float, not special buffer)?
function M.is_normal_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  local ft = vim.bo[buf].filetype
  local excluded = {
    snacks_dashboard = true,
    dashboard = true,
    Avante = true,
    AvanteInput = true,
    AvanteSelectedFiles = true,
    ["neo-tree"] = true,
    trouble = true,
    lazy = true,
    mason = true,
    TelescopePrompt = true,
    snacks_picker_input = true,
    snacks_picker_list = true,
    ["snacks_terminal"] = true,
  }
  return not excluded[ft]
end

return M
