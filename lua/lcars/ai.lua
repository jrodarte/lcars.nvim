-- AI subsystem status. Only reports what plugin APIs actually expose:
-- Avante (loaded / sidebar open / generating) and Copilot (status API).
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local function avante_status()
  local avante = package.loaded["avante"]
  if not avante then
    return util.has_plugin("avante.nvim") and "OFFLINE" or nil
  end
  local ok, cfg = pcall(require, "avante.config")
  if ok and cfg and cfg.provider then
    state.ai.provider = tostring(cfg.provider)
  end
  local ok2, sidebar = pcall(function()
    return avante.get and avante.get() or nil
  end)
  if ok2 and sidebar then
    if sidebar.is_generating then
      return "BUSY"
    end
    local open = false
    pcall(function()
      open = sidebar:is_open()
    end)
    if open then
      return "ACTIVE"
    end
  end
  return "READY"
end

local function copilot_status()
  if not package.loaded["copilot"] then
    return nil
  end
  local ok, api = pcall(require, "copilot.api")
  if not ok or not api.status then
    return nil
  end
  local s = api.status.data and api.status.data.status
  if s == "InProgress" then
    return "BUSY"
  elseif s == "Warning" then
    return "WARNING"
  elseif s == "Normal" then
    return "READY"
  end
  return nil
end

function M.poll()
  local a = avante_status()
  local c = copilot_status()
  state.ai.copilot = c
  state.ai.available = a ~= nil or c ~= nil
  if not state.ai.available then
    state.ai.status = "OFFLINE"
    return
  end
  if a == "BUSY" or c == "BUSY" then
    state.ai.status = "BUSY"
  elseif a == "ACTIVE" then
    state.ai.status = "ACTIVE"
  elseif a == "READY" or c == "READY" then
    state.ai.status = "READY"
  else
    state.ai.status = "OFFLINE"
  end
end

---@param group integer
function M.setup(group)
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "AvanteInputSubmitted", "AvanteEditSubmitted" },
    callback = function()
      state.ai.status = "BUSY"
      util.redrawstatus()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = function(ev)
      if ev.data == "avante.nvim" or ev.data == "copilot.lua" then
        vim.schedule(M.poll)
      end
    end,
  })
  M.poll()
end

function M.teardown() end

function M.label()
  local s = state.ai
  if not s.available then
    return nil
  end
  local name = s.provider and s.provider:upper() or "AI"
  if s.copilot and not package.loaded["avante"] then
    name = "COPILOT"
  end
  return name, s.status
end

return M
