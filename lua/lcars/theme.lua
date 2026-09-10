-- Applies the LCARS colorscheme and the Red Alert overlay.
local M = {}

local function cfg()
  return require("lcars.state").config or {}
end

--- Full colorscheme load (used by colors/lcars.lua).
function M.load()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.g.colors_name = "lcars"
  M.apply()
end

--- (Re)apply every LCARS highlight group without clearing first.
function M.apply()
  local c = cfg()
  local groups = require("lcars.highlights").get({
    transparent = c.transparent ~= false,
    dim_inactive = c.dim_inactive,
  })
  for name, attrs in pairs(groups) do
    if name == "terminal" then
      if c.terminal_colors ~= false then
        for i, hex in ipairs(attrs) do
          vim.g["terminal_color_" .. (i - 1)] = hex
        end
      end
    else
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
  if require("lcars.state").red_alert then
    M.apply_alert(true)
  end
end

--- Re-apply only the Lcars* groups (used when another colorscheme is loaded
--- while LCARS is enabled so the control surfaces keep rendering).
function M.apply_ui_groups()
  local c = cfg()
  local groups = require("lcars.highlights").get({
    transparent = c.transparent ~= false,
    dim_inactive = c.dim_inactive,
  })
  for name, attrs in pairs(groups) do
    if name:sub(1, 5) == "Lcars" then
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
  if require("lcars.state").red_alert then
    M.apply_alert(true)
  end
end

---@param on boolean
function M.apply_alert(on)
  if on then
    for name, attrs in pairs(require("lcars.highlights").alert()) do
      -- merge over the existing definition so bg/attrs survive
      local cur = vim.api.nvim_get_hl(0, { name = name, link = false })
      local merged = {}
      if cur.fg then
        merged.fg = cur.fg
      end
      if cur.bg then
        merged.bg = cur.bg
      end
      if cur.bold then
        merged.bold = true
      end
      if cur.italic then
        merged.italic = true
      end
      for k, v in pairs(attrs) do
        merged[k] = v
      end
      vim.api.nvim_set_hl(0, name, merged)
    end
  else
    if vim.g.colors_name == "lcars" then
      M.apply()
    else
      M.apply_ui_groups()
    end
  end
end

return M
