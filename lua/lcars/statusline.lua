-- LCARS system control strip. Pure function of cached state; no I/O.
-- Rendered through 'statusline' = "%{%v:lua.require'lcars.statusline'.render()%}"
local state = require("lcars.state")
local P = require("lcars.palette")
local util = require("lcars.util")

local M = {}

M.EXPR = "%{%v:lua.require'lcars.statusline'.render()%}"

local SPIN = { "◐", "◓", "◑", "◒" }
local HEART = { "●", "◉" }
local CAP_L, CAP_R = "", ""
local GAP = "%#StatusLine# "

local function cap(name)
  return name:sub(1, 1):upper() .. name:sub(2)
end

local hl_cache = {}
local function H(kind, color)
  local key = kind .. color
  local v = hl_cache[key]
  if not v then
    v = "Lcars" .. kind .. cap(color)
    hl_cache[key] = v
  end
  return v
end

local function spinner()
  return SPIN[(state.tick % #SPIN) + 1]
end

-- Part builders --------------------------------------------------------------
-- A segment is { id, prio, parts = { {text, hl}, ... }, short = parts? }
local function block(color, text)
  return { " " .. text .. " ", H("Block", color) }
end
local function read(color, text)
  return { " " .. text .. " ", H("Read", color) }
end
local function readparts(parts)
  -- parts: list of {text, color} rendered inside one dark readout
  local out = { { " ", "LcarsReadText" } }
  for _, p in ipairs(parts) do
    out[#out + 1] = { p[1], p[2] and H("Read", p[2]) or "LcarsReadText" }
  end
  out[#out + 1] = { " ", "LcarsReadText" }
  return out
end

-- Flatten a mixed list of parts / part-lists into one flat part list.
local function flatten(list)
  local out = {}
  for _, p in ipairs(list or {}) do
    if type(p[1]) == "string" then
      out[#out + 1] = p
    else
      for _, q in ipairs(p) do
        out[#out + 1] = q
      end
    end
  end
  return out
end

local function seg(id, prio, parts, short)
  return { id = id, prio = prio, parts = flatten(parts), short = short and flatten(short) or nil }
end

-- Segments -------------------------------------------------------------------

local function seg_lcars()
  local anim = state.config.animations and state.config.animations.enabled
  local color = state.red_alert and "red_bright" or P.roles.brand
  local label = "LCARS " .. (state.ids.lcars or 47)
  if state.red_alert then
    label = (anim and state.tick % 2 == 0) and "▲ RED ALERT" or "  RED ALERT"
  end
  local parts = { block(color, label) }
  if state.config.heartbeat ~= false then
    local heart = anim and HEART[(state.tick % 2) + 1] or HEART[1]
    local seq = state.seq and table.concat(state.seq, "·") or ""
    parts[#parts + 1] = readparts({ { heart, P.roles.heartbeat }, { " " .. seq, "gray" } })
    return seg("lcars", 0, parts, { block(color, state.red_alert and "ALERT" or "LCARS") })
  end
  return seg("lcars", 0, parts, { block(color, "LCARS") })
end

local function seg_mode()
  local m = state.mode
  local color = state.red_alert and "tomato" or m.color
  return seg("mode", 0, { block(color, m.label) }, { block(color, m.short) })
end

local function seg_project()
  local name = state.project.name
  if not name or name == "" then
    return nil
  end
  return seg("project", 5, { read(P.roles.project, name:upper()) })
end

local function seg_git()
  local git = require("lcars.git")
  local branch = git.branch()
  if not branch then
    return nil
  end
  local g = state.git
  local items = { { branch, "lilac" } }
  local diff = git.buffer_diff()
  if diff then
    if diff.added > 0 then
      items[#items + 1] = { " +" .. diff.added, "green" }
    end
    if diff.changed > 0 then
      items[#items + 1] = { " ~" .. diff.changed, "amber" }
    end
    if diff.removed > 0 then
      items[#items + 1] = { " -" .. diff.removed, "red" }
    end
  end
  if g.available then
    if g.staged > 0 then
      items[#items + 1] = { " S" .. g.staged, "green" }
    end
    if g.modified > 0 then
      items[#items + 1] = { " M" .. g.modified, "amber" }
    end
    if g.untracked > 0 then
      items[#items + 1] = { " ?" .. g.untracked, "gray" }
    end
    if g.ahead > 0 then
      items[#items + 1] = { " ↑" .. g.ahead, "ice" }
    end
    if g.behind > 0 then
      items[#items + 1] = { " ↓" .. g.behind, "salmon" }
    end
  end
  local label = g.worktree and "WORKTREE" or "GIT"
  local short_branch = #branch > 18 and (branch:sub(1, 17) .. "…") or branch
  return seg(
    "git",
    3,
    { block(P.roles.git, label), readparts(items) },
    { block(P.roles.git, g.worktree and "WT" or "GIT"), read(P.roles.git, short_branch) }
  )
end

local function seg_filetype()
  local ft = vim.bo.filetype
  local label = P.filetypes[ft]
  if not label then
    if ft == "" then
      return nil
    end
    label = ft:upper()
  end
  return seg("filetype", 6, { read(P.roles.filetype, label) })
end

local function seg_python()
  local p = state.python
  local ft = vim.bo.filetype
  local relevant = ft == "python" or ft == "requirements" or ft == "toml" or (p.venv ~= nil and ft == "")
  if not relevant and not state.config.python_always then
    -- only show the Python subsystem when it is contextually useful
    if ft ~= "python" then
      return nil
    end
  end
  local py = require("lcars.python")
  local items = { { p.version or "?", "sky" } }
  if p.venv then
    items[#items + 1] = { " · " .. p.venv, "text_dim" }
  end
  if p.ruff then
    items[#items + 1] = { " RUFF", "green" }
  end
  if p.formatter then
    items[#items + 1] = { " " .. p.formatter, "lavender" }
  end
  return seg(
    "python",
    4,
    { block(P.roles.python, "PYTHON"), readparts(items) },
    { block(P.roles.python, "PY"), read(P.roles.python, (p.version or "?"):match("^%d+%.%d+") or "?") }
  )
end

local function seg_lsp()
  local names = state.lsp.clients
  local color = P.roles.lsp
  if #names == 0 then
    if vim.bo.buftype ~= "" or vim.bo.filetype == "" then
      return nil
    end
    return seg("lsp", 2, { block("gray3", "LSP"), read("gray", "OFFLINE") }, { block("gray3", "LSP") })
  end
  local anim = state.config.animations and state.config.animations.enabled
  local ind = state.lsp.busy and (anim and spinner() or "◐") or "●"
  local ind_color = state.lsp.busy and "amber" or "green"
  local list = table.concat(names, "+"):upper()
  return seg(
    "lsp",
    2,
    { block(color, "LSP"), readparts({ { list, "ice" }, { " " .. ind, ind_color } }) },
    { block(color, "LSP"), readparts({ { ind, ind_color } }) }
  )
end

local function seg_diag()
  local d = state.diag
  if vim.bo.buftype ~= "" then
    return nil
  end
  local items = {
    { "E" .. d.error, d.error > 0 and "red_bright" or "gray3" },
    { " W" .. d.warn, d.warn > 0 and "orange" or "gray3" },
  }
  if d.info > 0 then
    items[#items + 1] = { " I" .. d.info, "ice" }
  end
  if d.hint > 0 then
    items[#items + 1] = { " H" .. d.hint, "lavender" }
  end
  local short = {
    { "E" .. d.error, d.error > 0 and "red_bright" or "gray3" },
    { " W" .. d.warn, d.warn > 0 and "orange" or "gray3" },
  }
  local color = d.error > 0 and "tomato" or (d.warn > 0 and "orange" or "gray3")
  return seg("diag", 1, { block(color, "DIAG"), readparts(items) }, { readparts(short) })
end

local function seg_tests()
  local label = require("lcars.tests").label()
  if not label then
    return nil
  end
  local t = state.tests
  local color = t.status == "PASS" and "green" or (t.status == "FAIL" and "tomato" or "amber")
  local anim = state.config.animations and state.config.animations.enabled
  if t.status == "RUNNING" then
    label = "VALIDATION " .. (anim and spinner() or "◐")
  end
  return seg("tests", 4, { block(color, "TEST"), read(color, label) }, { block(color, "T"), read(color, label) })
end

local function seg_dap()
  local d = state.dap
  if not d.active then
    return nil
  end
  local items = { { d.status, "salmon" } }
  if d.breakpoints > 0 then
    items[#items + 1] = { " BP" .. d.breakpoints, "amber" }
  end
  return seg("dap", 0, { block(P.roles.dap, "DEBUG"), readparts(items) }, { block(P.roles.dap, "DBG") })
end

local function seg_ai()
  local name, status = require("lcars.ai").label()
  if not name then
    return nil
  end
  local anim = state.config.animations and state.config.animations.enabled
  local color = status == "OFFLINE" and "gray3" or P.roles.ai
  local ind
  if status == "BUSY" then
    ind = anim and spinner() or "◐"
  elseif status == "ACTIVE" then
    ind = "◉"
  elseif status == "READY" then
    ind = "●"
  else
    ind = "○"
  end
  local ind_color = status == "BUSY" and "amber" or (status == "OFFLINE" and "gray" or "green")
  return seg("ai", 5, {
    block(color, "AI"),
    readparts({
      { name, "lavender" },
      { status ~= "READY" and (" " .. status) or "", "text_dim" },
      { " " .. ind, ind_color },
    }),
  }, { block(color, "AI"), readparts({ { ind, ind_color } }) })
end

local function seg_position()
  local line = vim.fn.line(".")
  local col = vim.fn.charcol(".")
  local total = vim.fn.line("$")
  local pct = total > 0 and math.floor(line * 100 / total) or 0
  local text = string.format("%d:%d", line, col)
  return seg(
    "position",
    1,
    { read(P.roles.position, string.format("%3d%%", pct)), block(P.roles.position, text) },
    { block(P.roles.position, text) }
  )
end

local function seg_time()
  return seg("time", 3, { block(P.roles.time, os.date("%H:%M")) })
end

local function seg_uptime()
  return seg("uptime", 6, { read("gray", "UP " .. util.fmt_duration(state.uptime())) })
end

local function seg_stardate()
  if not state.config.stardate then
    return nil
  end
  return seg("stardate", 7, { read("gray", "SD " .. util.stardate()) })
end

-- Rendering ----------------------------------------------------------------

local function parts_width(parts)
  local w = 0
  for _, p in ipairs(parts) do
    w = w + util.width(p[1])
  end
  return w
end

local function render_parts(parts)
  local out = {}
  for _, p in ipairs(parts) do
    out[#out + 1] = "%#" .. p[2] .. "#" .. util.esc(p[1])
  end
  return table.concat(out)
end

-- Add rounded caps to the outer ends of a cluster (only if the end is a block).
local function cluster(segs, left_cap, right_cap)
  local out = {}
  for i, s in ipairs(segs) do
    local parts = s.parts
    local str = render_parts(parts)
    if i == 1 and left_cap then
      local first = parts[1]
      if first[2]:find("^LcarsBlock") then
        str = "%#" .. first[2]:gsub("Block", "Cap") .. "#" .. CAP_L .. str
      end
    end
    if i == #segs and right_cap then
      local last = parts[#parts]
      if last[2]:find("^LcarsBlock") then
        str = str .. "%#" .. last[2]:gsub("Block", "Cap") .. "#" .. CAP_R
      end
    end
    out[#out + 1] = str
  end
  return table.concat(out, GAP)
end

local function total_width(L, R)
  local w = 0
  for _, s in ipairs(L) do
    w = w + parts_width(s.parts) + 1
  end
  for _, s in ipairs(R) do
    w = w + parts_width(s.parts) + 1
  end
  return w + 2 -- caps
end

function M.render()
  local ok, res = pcall(M._render)
  if ok then
    return res
  end
  return "%#ErrorMsg# LCARS STATUSLINE FAULT: " .. util.esc(tostring(res)) .. " "
end

function M._render()
  local c = state.config
  local left, right = {}, {}
  local order = 0
  local function push(list, s)
    if s then
      order = order + 1
      s._i = order
      list[#list + 1] = s
    end
  end
  push(left, seg_lcars())
  push(left, seg_mode())
  push(left, seg_project())
  if c.git ~= false then
    push(left, seg_git())
  end
  if c.python ~= false then
    push(right, seg_python())
  end
  push(right, seg_lsp())
  if c.diagnostics ~= false then
    push(right, seg_diag())
  end
  if c.tests ~= false then
    push(right, seg_tests())
  end
  if c.dap ~= false then
    push(right, seg_dap())
  end
  if c.ai ~= false then
    push(right, seg_ai())
  end
  push(right, seg_position())
  push(right, seg_time())
  push(right, seg_uptime())
  push(right, seg_stardate())

  local columns = vim.o.columns
  local min_rail = 3

  -- Degrade gracefully: shorten the least important segment first, then
  -- drop segments by priority, until the strip fits the window.
  local function too_wide()
    return total_width(left, right) + min_rail > columns
  end
  local function pick(list_pred)
    local worst, wlist, widx = -1, nil, nil
    for _, list in ipairs({ left, right }) do
      for i, s in ipairs(list) do
        if list_pred(s) and s.prio > worst then
          worst, wlist, widx = s.prio, list, i
        end
      end
    end
    return wlist, widx
  end
  while too_wide() do
    -- least important segment first: shorten it if it can be, else drop it
    local wlist, widx = pick(function()
      return true
    end)
    if not wlist then
      break
    end
    local s = wlist[widx]
    if s.short then
      s.parts, s.short = s.short, nil
    elseif s.prio > 0 then
      table.remove(wlist, widx)
    else
      -- essential segments are already compact; try compacting any remaining
      wlist, widx = pick(function(x)
        return x.short ~= nil
      end)
      if not wlist then
        break
      end
      wlist[widx].parts, wlist[widx].short = wlist[widx].short, nil
    end
  end

  local rail_w = math.max(0, columns - total_width(left, right))
  local rail_hl = state.red_alert and "LcarsRailAlert" or "LcarsRail"
  local rail = "%#" .. rail_hl .. "#%<" .. string.rep("━", math.max(0, rail_w - 2))

  local ls = #left > 0 and cluster(left, true, false) or ""
  local rs = #right > 0 and cluster(right, false, true) or ""
  return ls .. GAP .. rail .. "%=" .. GAP .. rs .. "%#StatusLine#"
end

-- Mode tracking ------------------------------------------------------------

function M.update_mode()
  local raw = vim.api.nvim_get_mode().mode
  local key = raw
  local def = P.modes[key]
  if not def then
    key = raw:sub(1, 2)
    def = P.modes[key]
  end
  if not def then
    key = raw:sub(1, 1)
    def = P.modes[key] or P.modes.n
  end
  state.mode = { raw = raw, label = def.label, short = def.short, color = def.color }
end

-- Enable / disable ------------------------------------------------------------

---@param group integer
function M.setup(group)
  M.update_mode()
  state.prev.statusline = vim.o.statusline
  state.prev.laststatus = vim.o.laststatus
  local lualine = package.loaded["lualine"]
  if lualine then
    pcall(lualine.hide, { place = { "statusline" }, unhide = false })
  end
  vim.o.laststatus = 3
  vim.o.statusline = M.EXPR
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      M.update_mode()
      util.redrawstatus()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = function()
      state.project.root = util.root()
      state.project.name = util.project_name(state.project.root)
    end,
  })
  state.project.root = util.root()
  state.project.name = util.project_name(state.project.root)
end

function M.teardown()
  local lualine = package.loaded["lualine"]
  if lualine then
    -- lualine restores its own statusline expression and laststatus
    pcall(lualine.hide, { place = { "statusline" }, unhide = true })
  end
  if vim.o.statusline == M.EXPR then
    vim.o.statusline = state.prev.statusline or ""
  end
  if state.prev.laststatus and not lualine then
    vim.o.laststatus = state.prev.laststatus
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.wo[win].statusline == M.EXPR then
      vim.wo[win].statusline = ""
    end
  end
end

return M
