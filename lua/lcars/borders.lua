-- LCARS border geometry. Left edges are rounded (LCARS elbows), right edges
-- square, so panels read as asymmetric LCARS frames rather than generic boxes.
local M = {}

-- Order: top-left, top, top-right, right, bottom-right, bottom, bottom-left, left
M.normal = { "╭", "─", "┐", "│", "┘", "─", "╰", "│" }
M.search = { "╭", "─", "┐", "│", "┘", "─", "╰", "┃" }
M.warning = { "╭", "━", "┓", "┃", "┛", "━", "╰", "┃" }
M.error = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }
M.alert = M.error
M.debug = { "╭", "─", "┐", "┃", "┘", "─", "╰", "┃" }
M.ai = { "╭", "─", "┐", "│", "┘", "─", "╰", "▌" }
M.status = { "╭", "─", "┐", "│", "┘", "─", "╰", "▌" }

--- Border with per-side highlight groups, usable by nvim_open_win / Snacks.
---@param chars string[]
---@param hl string
function M.with_hl(chars, hl)
  local out = {}
  for i, ch in ipairs(chars) do
    out[i] = { ch, hl }
  end
  return out
end

return M
