-- Restyle bufferline.nvim as an LCARS buffer strip while enabled, and put the
-- user's own configuration back on disable.
local P = require("lcars.palette")
local util = require("lcars.util")

local M = {}

local function base_opts()
  local ok, o = pcall(function()
    return LazyVim.opts("bufferline.nvim")
  end)
  return ok and vim.deepcopy(o) or {}
end

local function lcars_opts()
  local c = P.colors
  local function blk(color, extra)
    return vim.tbl_extend("force", { fg = c.black, bg = color, bold = true, italic = false }, extra or {})
  end
  local dark = { fg = c.muted, bg = c.panel, bold = false, italic = false }
  local dark_dim = { fg = c.gray3, bg = c.panel, bold = false, italic = false }
  return {
    options = {
      numbers = function(o)
        return string.format("%02d", o.ordinal)
      end,
      separator_style = { " ", " " },
      indicator = { style = "none" },
      show_buffer_close_icons = false,
      show_close_icon = false,
      show_buffer_icons = false,
      modified_icon = "●",
      left_trunc_marker = "◀",
      right_trunc_marker = "▶",
      always_show_bufferline = false,
      tab_size = 14,
    },
    highlights = {
      fill = { bg = "NONE" },
      background = dark,
      buffer_selected = blk(c.orange),
      buffer_visible = { fg = c.text_dim, bg = c.panel, bold = false, italic = false },
      numbers = { fg = c.gray, bg = c.panel },
      numbers_selected = blk(c.orange),
      numbers_visible = { fg = c.gray, bg = c.panel },
      separator = { fg = c.black, bg = "NONE" },
      separator_selected = { fg = c.black, bg = "NONE" },
      separator_visible = { fg = c.black, bg = "NONE" },
      indicator_selected = blk(c.orange),
      indicator_visible = { fg = c.panel, bg = c.panel },
      modified = { fg = c.amber, bg = c.panel },
      modified_selected = blk(c.amber),
      modified_visible = { fg = c.amber, bg = c.panel },
      tab = { fg = c.gray, bg = c.panel },
      tab_selected = blk(c.lilac),
      tab_separator = { fg = c.black, bg = "NONE" },
      tab_separator_selected = { fg = c.black, bg = "NONE" },
      tab_close = { fg = c.gray, bg = "NONE" },
      close_button = dark,
      close_button_selected = blk(c.orange),
      close_button_visible = dark,
      trunc_marker = { fg = c.orange, bg = "NONE" },
      offset_separator = { fg = c.gray2, bg = "NONE" },
      diagnostic = dark,
      diagnostic_selected = blk(c.orange),
      diagnostic_visible = dark,
      error = { fg = c.red, bg = c.panel },
      error_selected = blk(c.tomato),
      error_visible = { fg = c.red, bg = c.panel },
      error_diagnostic = { fg = c.red, bg = c.panel },
      error_diagnostic_selected = blk(c.tomato),
      error_diagnostic_visible = { fg = c.red, bg = c.panel },
      warning = { fg = c.amber, bg = c.panel },
      warning_selected = blk(c.amber),
      warning_visible = { fg = c.amber, bg = c.panel },
      warning_diagnostic = { fg = c.amber, bg = c.panel },
      warning_diagnostic_selected = blk(c.amber),
      warning_diagnostic_visible = { fg = c.amber, bg = c.panel },
      info = { fg = c.ice, bg = c.panel },
      info_selected = blk(c.ice),
      info_visible = { fg = c.ice, bg = c.panel },
      info_diagnostic = { fg = c.ice, bg = c.panel },
      info_diagnostic_selected = blk(c.ice),
      info_diagnostic_visible = { fg = c.ice, bg = c.panel },
      hint = { fg = c.lavender, bg = c.panel },
      hint_selected = blk(c.lavender),
      hint_visible = { fg = c.lavender, bg = c.panel },
      hint_diagnostic = { fg = c.lavender, bg = c.panel },
      hint_diagnostic_selected = blk(c.lavender),
      hint_diagnostic_visible = { fg = c.lavender, bg = c.panel },
      duplicate = dark_dim,
      duplicate_selected = blk(c.orange, { italic = false }),
      duplicate_visible = dark_dim,
      pick = blk(c.amber),
      pick_selected = blk(c.amber),
      pick_visible = blk(c.amber),
    },
  }
end

local function apply(opts)
  local bl = util.try_require("bufferline")
  if not bl then
    return
  end
  local ok, err = pcall(bl.setup, opts)
  if not ok then
    vim.schedule(function()
      vim.notify("LCARS bufferline restyle failed: " .. tostring(err), vim.log.levels.WARN)
    end)
  end
end

function M.enable()
  if not util.plugin_loaded("bufferline.nvim") then
    return
  end
  apply(vim.tbl_deep_extend("force", base_opts(), lcars_opts()))
end

function M.disable()
  if not util.plugin_loaded("bufferline.nvim") then
    return
  end
  apply(base_opts())
end

return M
