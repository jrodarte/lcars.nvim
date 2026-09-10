-- LCARS winbar: SYS ID ▏ PROJECT › dir › file › symbol
-- Set per-window so special buffers (terminals, Avante, pickers) are untouched.
local state = require("lcars.state")
local util = require("lcars.util")
local P = require("lcars.palette")

local M = {}

M.EXPR = "%{%v:lua.require'lcars.winbar'.render()%}"

local symbols = nil -- trouble statusline handle (created once, reused)

local function get_symbols()
  if symbols ~= nil then
    return symbols or nil
  end
  if not util.has_plugin("trouble.nvim") then
    symbols = false
    return nil
  end
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    symbols = false
    return nil
  end
  local ok2, s = pcall(trouble.statusline, {
    mode = "symbols",
    groups = {},
    title = false,
    filter = { range = true },
    format = "{kind_icon}{symbol.name:LcarsWinbarSymbol}",
    hl_group = "LcarsWinbarSymbol",
  })
  symbols = ok2 and s or false
  return symbols or nil
end

local function hl(group, text)
  return "%#" .. group .. "#" .. util.esc(text)
end

function M.render()
  local ok, res = pcall(M._render)
  if ok then
    return res
  end
  return "%#ErrorMsg# LCARS WINBAR FAULT "
end

function M._render()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local active = win == vim.api.nvim_get_current_win()
  local name = vim.api.nvim_buf_get_name(buf)
  local root = state.project.root or util.root()
  local project = (state.project.name or util.project_name(root)):upper()

  local id = string.format("SYS %03d", state.ids.sys or 0)
  local out = {}
  if active then
    out[#out + 1] = hl("LcarsWinbarIdCap", "") .. hl("LcarsWinbarId", id) .. hl("LcarsWinbarIdCap", "")
  else
    out[#out + 1] = hl("LcarsWinbarIdCapNC", "") .. hl("LcarsWinbarIdNC", id) .. hl("LcarsWinbarIdCapNC", "")
  end
  out[#out + 1] = " "

  local dir_hl = active and "LcarsWinbarDir" or "LcarsWinbarNC"
  local sep_hl = active and "LcarsWinbarSep" or "LcarsWinbarNC"
  local proj_hl = active and "LcarsWinbarProject" or "LcarsWinbarNC"
  local sep = hl(sep_hl, " › ")

  out[#out + 1] = hl(proj_hl, project)

  local rel
  if name == "" then
    rel = "[NO NAME]"
  elseif root and name:sub(1, #root) == root then
    rel = name:sub(#root + 2)
  else
    rel = vim.fn.fnamemodify(name, ":~")
  end
  local pieces = vim.split(rel, "/", { plain = true })
  local file = table.remove(pieces)
  -- collapse deep paths
  if #pieces > 3 then
    pieces = { pieces[1], "…", pieces[#pieces - 1], pieces[#pieces] }
  end
  for _, d in ipairs(pieces) do
    if d ~= "" then
      out[#out + 1] = sep .. hl(dir_hl, d)
    end
  end
  local modified = vim.bo[buf].modified
  local file_hl = not active and "LcarsWinbarNC" or (modified and "LcarsWinbarFileMod" or "LcarsWinbarFile")
  out[#out + 1] = sep .. hl(file_hl, file .. (modified and " ●" or ""))

  if active then
    local s = get_symbols()
    if s and s.has() then
      local sym = s.get()
      if sym and sym ~= "" then
        out[#out + 1] = sep .. sym
      end
    end
    local label = P.filetypes[vim.bo[buf].filetype]
    if label then
      out[#out + 1] = "%=" .. hl("LcarsWinbarLabel", label .. " ")
    end
  end
  return table.concat(out)
end

local function attach(win)
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local cur = vim.wo[win].winbar
  if util.is_normal_win(win) then
    if cur == "" or cur == M.EXPR then
      vim.wo[win].winbar = M.EXPR
    end
  elseif cur == M.EXPR then
    vim.wo[win].winbar = ""
  end
end

---@param group integer
function M.setup(group)
  state.prev.winbar = vim.o.winbar
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType", "TermOpen" }, {
    group = group,
    callback = function()
      attach()
    end,
  })
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    attach(win)
  end
end

function M.teardown()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].winbar == M.EXPR then
      vim.wo[win].winbar = ""
    end
  end
  if vim.o.winbar == M.EXPR then
    vim.o.winbar = state.prev.winbar or ""
  end
end

return M
