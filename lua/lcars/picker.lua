-- Snacks picker as an LCARS database terminal: prompt, panel titles, borders.
local state = require("lcars.state")
local borders = require("lcars.borders")

local M = {}

local function layouts()
  local wide = {
    layout = {
      box = "horizontal",
      width = 0.85,
      min_width = 120,
      height = 0.8,
      {
        box = "vertical",
        border = borders.search,
        title = " LCARS DATABASE QUERY ▸ {title} {live} {flags}",
        title_pos = "left",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
      { win = "preview", title = " PREVIEW ▸ {preview} ", title_pos = "left", border = borders.normal, width = 0.5 },
    },
  }
  local narrow = {
    layout = {
      backdrop = false,
      width = 0.9,
      min_width = 60,
      height = 0.9,
      min_height = 3,
      box = "vertical",
      border = borders.search,
      title = " LCARS DATABASE QUERY ▸ {title} {live} {flags}",
      title_pos = "left",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
      { win = "preview", title = " PREVIEW ▸ {preview} ", title_pos = "left", height = 0.4, border = "top" },
    },
  }
  local select = {
    preview = false,
    layout = {
      backdrop = false,
      width = 0.5,
      min_width = 40,
      height = 0.4,
      min_height = 3,
      box = "vertical",
      border = borders.normal,
      title = " LCARS SELECT ▸ {title} ",
      title_pos = "left",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  }
  local center = vim.deepcopy(select)
  center.layout.title = " {title} "
  center.layout.width = 0.55
  center.layout.height = 0.5
  return { lcars = wide, lcars_vertical = narrow, lcars_select = select, lcars_center = center }
end

function M.enable()
  if not package.loaded["snacks"] then
    return
  end
  Snacks.config.picker = Snacks.config.picker or {}
  local pc = Snacks.config.picker
  state.prev.picker_prompt = pc.prompt
  state.prev.picker_layout = pc.layout
  state.prev.picker_layouts = pc.layouts
  pc.prompt = "QUERY ▸ "
  pc.layouts = vim.tbl_extend("force", pc.layouts or {}, layouts())
  pc.layout = {
    preset = function(source)
      if source == "lcars_center" then
        return "lcars_center"
      elseif source == "select" then
        return "lcars_select"
      end
      return vim.o.columns >= 120 and "lcars" or "lcars_vertical"
    end,
  }
end

function M.disable()
  if not package.loaded["snacks"] or not Snacks.config.picker then
    return
  end
  local pc = Snacks.config.picker
  pc.prompt = state.prev.picker_prompt
  pc.layout = state.prev.picker_layout
  pc.layouts = state.prev.picker_layouts
end

return M
