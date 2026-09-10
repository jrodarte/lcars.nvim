-- One lightweight libuv timer drives every animated indicator. Nothing else
-- in LCARS owns a repeating timer.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local timer = util.timer()

local function rotate_seq()
  local seq = state.seq or { 17, 42, 9 }
  table.remove(seq, 1)
  seq[#seq + 1] = math.random(0, 99)
  for i, v in ipairs(seq) do
    seq[i] = string.format("%02d", tonumber(v) or 0)
  end
  state.seq = seq
end

local function tick()
  if not state.enabled then
    return M.stop()
  end
  if not state.focused then
    return
  end
  state.tick = state.tick + 1
  if state.tick % 2 == 0 then
    rotate_seq()
  end
  -- cheap polls of plugin state that has no event
  if state.tick % 2 == 0 or state.ai.status == "BUSY" then
    pcall(require("lcars.ai").poll)
  end
  if state.dap.active then
    pcall(require("lcars.dap").poll)
  end
  util.redrawstatus()
  pcall(require("lcars.system").refresh_window)
  if state.tick % 2 == 0 then
    pcall(require("lcars.dashboard").on_tick)
  end
end

function M.interval()
  local a = state.config.animations or {}
  return math.max(250, tonumber(a.interval) or 750)
end

function M.enabled()
  local a = state.config.animations or {}
  return a.enabled ~= false
end

function M.running()
  return timer:running()
end

function M.start()
  if not state.enabled or not M.enabled() then
    return
  end
  if timer:running() then
    return
  end
  timer:start(M.interval(), tick, true)
  state.animating = true
end

function M.stop()
  timer:stop()
  state.animating = false
end

function M.pause()
  state.focused = false
  timer:stop() -- no wakeups at all while Neovim is unfocused
  state.animating = false
end

function M.resume()
  state.focused = true
  if state.enabled and M.enabled() and not timer:running() then
    timer:start(M.interval(), tick, true)
    state.animating = true
  end
end

function M.enable()
  state.config.animations = state.config.animations or {}
  state.config.animations.enabled = true
  M.start()
  util.redrawstatus()
end

function M.disable()
  state.config.animations = state.config.animations or {}
  state.config.animations.enabled = false
  M.stop()
  util.redrawstatus()
end

function M.toggle()
  if M.enabled() then
    M.disable()
  else
    M.enable()
  end
  return M.enabled()
end

---@param group integer
function M.setup(group)
  if not state.seq then
    state.seq = {}
    for i = 1, 3 do
      state.seq[i] = string.format("%02d", math.random(0, 99))
    end
  end
  local a = state.config.animations or {}
  if a.pause_unfocused ~= false then
    vim.api.nvim_create_autocmd("FocusLost", {
      group = group,
      callback = function()
        M.pause()
      end,
    })
    vim.api.nvim_create_autocmd("FocusGained", {
      group = group,
      callback = function()
        M.resume()
        util.redrawstatus()
      end,
    })
  end
  M.start()
end

function M.teardown()
  M.stop()
end

return M
