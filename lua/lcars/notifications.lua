-- LCARS notification presentation (Snacks notifier style) and the contextual
-- "system message" helper used by collectors when real events happen.
local state = require("lcars.state")
local borders = require("lcars.borders")

local M = {}

local HEADERS = {
  info = "COMPUTER",
  warn = "SYSTEM ADVISORY",
  error = "LCARS ALERT",
  debug = "DIAGNOSTIC",
  trace = "TELEMETRY",
}

local BORDERS = {
  info = borders.normal,
  warn = borders.warning,
  error = borders.error,
  debug = borders.debug,
  trace = borders.normal,
}

--- Snacks notifier render style. Presentation only: the message body is
--- passed through untouched.
---@param buf number
---@param notif snacks.notifier.Notif
---@param ctx snacks.notifier.ctx
function M.style(buf, notif, ctx)
  local level = tostring(notif.level or "info")
  local header = HEADERS[level] or "COMPUTER"
  local title = notif.title and vim.trim(notif.title) or ""
  if title ~= "" then
    title = header .. " ▸ " .. title:upper()
  else
    title = header
  end
  ctx.opts.title = { { " " .. title .. " ", ctx.hl.title } }
  ctx.opts.title_pos = "left"
  ctx.opts.border = BORDERS[level] or borders.normal
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(notif.msg, "\n"))
end

--- The default Snacks "compact" style, reproduced so the dispatcher can fall
--- back to stock behaviour when LCARS is off.
function M.compact(buf, notif, ctx)
  local title = vim.trim(notif.icon .. " " .. (notif.title or ""))
  if title ~= "" then
    ctx.opts.title = { { " " .. title .. " ", ctx.hl.title } }
    ctx.opts.title_pos = "center"
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(notif.msg, "\n"))
end

--- Style dispatcher registered with Snacks at plugin-spec time. Toggle-safe:
--- reads runtime state on every render.
function M.dispatch(buf, notif, ctx)
  if state.enabled and (state.config.notifications ~= false) then
    return M.style(buf, notif, ctx)
  end
  return M.compact(buf, notif, ctx)
end

local last = {} ---@type table<string, number>

--- Emit a contextual system message tied to a real event. De-duplicated per
--- key within `cooldown` seconds so the same event never spams.
---@param key string
---@param msg string
---@param opts? {level?: number, title?: string, cooldown?: number, timeout?: number}
function M.event(key, msg, opts)
  if not state.enabled or state.config.system_messages == false then
    return
  end
  opts = opts or {}
  local now = os.time()
  if last[key] and now - last[key] < (opts.cooldown or 5) then
    return
  end
  last[key] = now
  vim.schedule(function()
    vim.notify(msg, opts.level or vim.log.levels.INFO, {
      title = opts.title or "LCARS",
      timeout = opts.timeout or 2500,
    })
  end)
end

function M.reset()
  last = {}
end

return M
