-- LCARS startup screen built on Snacks dashboard (already provided by LazyVim).
-- `sections_dispatch` is installed at plugin-spec time and decides per render
-- whether to show the LCARS layout or the stock one, so toggling is instant.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local DEFAULT_SECTIONS = {
  { section = "header" },
  { section = "keys", gap = 1, padding = 1 },
  { section = "startup" },
}

local BOOT = {
  "INITIALIZING LCARS INTERFACE",
  "LOADING DEVELOPMENT SUBSYSTEMS",
  "ESTABLISHING LANGUAGE SERVER LINK",
  "SCANNING PROJECT DATABASE",
  "INITIALIZING GIT TELEMETRY",
  "CONNECTING AI SUBSYSTEM",
  "SYSTEM READY",
}

local WIDTH = 78          -- total console width (sidebar + gap + content)
local SIDE = 12           -- LCARS sidebar column
local GAP = 2
local CONTENT = WIDTH - SIDE - GAP
local CAP_L, CAP_R = "\238\130\182", "\238\130\180" -- Nerd Font rounded pill ends (U+E0B6, U+E0B4)
local cascade = {} ---@type string[]
local boot_timer = util.timer()
local tick_n = 0

local function rand_cascade()
  local rows = {}
  for r = 1, 3 do
    local cells = {}
    for _ = 1, 5 do
      cells[#cells + 1] = string.format("%03d %02d %03d", math.random(0, 999), math.random(0, 99), math.random(0, 999))
    end
    rows[r] = table.concat(cells, "  ")
  end
  cascade = rows
end

local function pad(text, width, align)
  local w = util.width(text)
  if w >= width then
    return text
  end
  local fill = width - w
  if align == "right" then
    return string.rep(" ", fill) .. text
  elseif align == "center" then
    local l = math.floor(fill / 2)
    return string.rep(" ", l) .. text .. string.rep(" ", fill - l)
  end
  return text .. string.rep(" ", fill)
end

local function cap(name)
  return name:sub(1, 1):upper() .. name:sub(2)
end

-- Block glyphs (UTF-8 byte escapes; PUA/box glyphs do not survive every editor).
local G = {
  full = "\226\150\136",  -- █
  upper = "\226\150\128", -- ▀
  lower = "\226\150\132", -- ▄
  ul = "\226\150\152",    -- ▘ upper-left quadrant
  ur = "\226\150\157",    -- ▝ upper-right quadrant
  ll = "\226\150\150",    -- ▖ lower-left quadrant
  lr = "\226\150\151",    -- ▗ lower-right quadrant
  tl_cut = "\226\150\155", -- ▛ block minus lower-right
  tr_cut = "\226\150\156", -- ▜ block minus lower-left
  bl_cut = "\226\150\153", -- ▙ block minus upper-right
  br_cut = "\226\150\159", -- ▟ block minus upper-left
}

-- Segment helpers (Snacks text segments are { "str", hl = "Group" }) ----------
local function seg(text, hl)
  return { text, hl = hl }
end
local function blk(color, text)
  return { text, hl = "LcarsBlock" .. cap(color) }
end
local function capl(color)
  return { CAP_L, hl = "LcarsCap" .. cap(color) }
end
local function capr(color)
  return { CAP_R, hl = "LcarsCap" .. cap(color) }
end
--- Rounded LCARS pill: `[ label ]` in a solid colour with black text.
local function pill(color, label, width)
  local inner = " " .. label .. " "
  if width then
    inner = pad(inner, width - 2, "center")
  end
  return { capl(color), blk(color, inner), capr(color) }
end
local function extend(t, segs)
  for _, sgm in ipairs(segs) do
    t[#t + 1] = sgm
  end
  return t
end

--- UTF-8 encode a code point (Lua 5.1 / LuaJIT has no utf8.char).
local function uchar(cp)
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
  elseif cp < 0x10000 then
    return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
  end
  return string.char(0xF0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40,
    0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
end

local R_COLS, R_ROWS = 6, 3 -- outer elbow radius in cells (matches the desktop console's proportions)

-- Outer quarter-circle of each elbow, one entry per cell: { codepoint, inverted }.
-- Chosen offline by measuring the real pixel coverage of every glyph a terminal
-- draws natively (sextants, eighth blocks, legacy wedges, triangles) and picking,
-- per cell, the glyph - or its black-on-colour inverse - closest to a true circle
-- of radius 6 columns.  Rows run top to bottom.
local CORNER_TOP = {
    { { 0x20, false }, { 0x1FB5D, true }, { 0x1FB46, false }, { 0x2586, false }, { 0x2587, false }, { 0x2588, false } },
    { { 0x25E2, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false } },
    { { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false } },
}
local CORNER_BOTTOM = {
    { { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false } },
    { { 0x25E5, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false }, { 0x2588, false } },
    { { 0x20, false }, { 0x1FB4C, true }, { 0x1FB51, true }, { 0x2582, true }, { 0x2581, true }, { 0x2588, false } },
}

--- Segments for the `R_COLS` corner cells of one row of an elbow.  In terminals
--- with kitty graphics the corner is a real anti-aliased image (see graphics.lua);
--- elsewhere the measured block glyphs above.
local function corner_segs(color, row, bottom)
  local gfx = require("lcars.graphics")
  if gfx.supported() then
    local key = (bottom and "bottom-" or "top-") .. color
    if gfx.ensure(key) then
      local text, hl = gfx.placeholder_row(key, row)
      return { seg(text, hl) }
    end
  end
  local cells = (bottom and CORNER_BOTTOM or CORNER_TOP)[row + 1]
  local fg, inv = "LcarsCap" .. cap(color), "LcarsBlock" .. cap(color)
  local out, run, run_hl = {}, {}, nil
  local function flush()
    if #run > 0 then
      out[#out + 1] = seg(table.concat(run), run_hl)
      run = {}
    end
  end
  for _, cell in ipairs(cells) do
    local hl = cell[2] and inv or fg
    if hl ~= run_hl then
      flush()
      run_hl = hl
    end
    run[#run + 1] = uchar(cell[1])
  end
  flush()
  return out
end

--- Sidebar segments for a row that lies on an elbow's outer curve.
---@param color string
---@param row integer  0 = outermost (bar) row .. R_ROWS-1
---@param bottom? boolean
---@param label? string
local function curve(color, row, bottom, label)
  local t = { seg(" ", "LcarsGap") }
  extend(t, corner_segs(color, row, bottom))
  t[#t + 1] = blk(color, pad(label and (label .. " ") or "", SIDE - R_COLS, "right"))
  return t
end

--- Elbow junction: the sidebar column meets the horizontal bar with a concave
--- inner corner.  `top` = bar above (▛ + ▀), otherwise bar below (▙ + ▄).
local function elbow_row(color, bar_cols, top)
  local hl = "LcarsCap" .. cap(color)
  local corner = top and "\226\150\155" or "\226\150\153"  -- ▛ / ▙
  local half = top and "\226\150\128" or "\226\150\132"    -- ▀ / ▄
  local full = "\226\150\136"                                  -- █
  local t = { seg(" ", "LcarsGap") }
  extend(t, corner_segs(color, top and 1 or R_ROWS - 2, not top))
  t[#t + 1] = seg(string.rep(full, SIDE - R_COLS) .. corner .. string.rep(half, math.max(0, bar_cols)), hl)
  return { text = t }
end

--- Sidebar cell for one console row: solid block, optional label on the row.
local function side(color, label)
  return blk(color, pad(label and (label .. " ") or "", SIDE, "right"))
end

--- Console row: sidebar block + gap + content segments padded to CONTENT.
local function crow(color, label, segs, opts, edge)
  local t
  if edge then
    t = curve(color, edge.row, edge.bottom, label)
  else
    t = { seg(" ", "LcarsGap"), side(color, label) }
  end
  t[#t + 1] = seg(string.rep(" ", GAP), "LcarsGap")
  extend(t, segs)
  local item = { text = t }
  if opts then
    for k, v in pairs(opts) do
      item[k] = v
    end
  end
  return item
end

--- Fill segment so the content area reaches CONTENT columns.
local function filler(segs, hl)
  local w = 0
  for _, sgm in ipairs(segs) do
    w = w + util.width(sgm[1])
  end
  return seg(string.rep(" ", math.max(0, CONTENT - w)), hl or "LcarsGap")
end

local function frame_colors()
  local s = state
  if s.red_alert then
    return { top = "red_bright", side1 = "salmon", side2 = "red", side3 = "salmon", side4 = "red", bottom = "red", accent = "salmon" }
  end
  return { top = "orange", side1 = "amber", side2 = "lilac", side3 = "peach", side4 = "blue_muted", bottom = "blue_muted", accent = "lilac" }
end

-- Sections -----------------------------------------------------------------

local function header_items()
  local s, fc = state, frame_colors()
  local ident = "LCARS " .. (s.ids.lcars or 47)
  local sys = string.format("SYS %03d", s.ids.sys or 0)
  local title = " COMPUTER ACCESS "
  -- L1: top rail (elbow corner is the sidebar colour continuing into the bar)
  local l1 = { seg(" ", "LcarsGap") }
  extend(l1, corner_segs(fc.top, 0, false))
  extend(l1, { blk(fc.top, pad(" " .. ident, SIDE - R_COLS + GAP + 2)), seg(title, "LcarsText" .. cap(fc.top)) })
  local used = 1 + SIDE + GAP + 2 + util.width(title)
  local right = 8 + 1 + 4 + 1 + 1 -- lilac 8, gap, peach 4, cap
  local mid = WIDTH - used - right - 1
  extend(l1, {
    blk(fc.top, string.rep(" ", math.max(1, mid))),
    seg(" ", "LcarsGap"),
    blk(fc.accent, string.rep(" ", 8)),
    seg(" ", "LcarsGap"),
    blk("peach", string.rep(" ", 4)),
    capr("peach"),
  })
  -- L2: subtitle + stardate
  local sub = "U.S.S. VOYAGER DEVELOPMENT SYSTEM"
  local sd = "STARDATE " .. util.stardate()
  local l2 = { seg(sub, "LcarsDashSubtitle"), seg(string.rep(" ", CONTENT - util.width(sub) - util.width(sd) - 12), "LcarsGap") }
  extend(l2, pill("gray2", sd))
  -- L3: boot status + segmented progress
  local phase = math.min(#BOOT, math.max(1, s.boot.phase))
  local msg = s.boot.done and BOOT[#BOOT] or BOOT[phase]
  local segs_on = s.boot.done and #BOOT or phase
  local l3 = { seg(pad(msg, CONTENT - #BOOT * 3 - 4), s.boot.done and "LcarsDashOnline" or "LcarsDashBoot") }
  for i = 1, #BOOT do
    local lit = i <= segs_on
    local hl = lit and (s.boot.done and "LcarsBlockGreen" or "LcarsBlockAmber") or "LcarsBlockGray2"
    l3[#l3 + 1] = seg("  ", hl)
    l3[#l3 + 1] = seg(" ", "LcarsGap")
  end
  local bar_end = used + math.max(1, mid)          -- last column of the orange bar
  return {
    { text = l1 },
    elbow_row(fc.top, bar_end - (1 + SIDE + 1), true),
    crow(fc.top, nil, l2, nil, { row = 2 }),
    crow(fc.top, "CORE", l3, { padding = 1 }),
  }
end

local function status_items()
  local s, fc = state, frame_colors()
  local lsp = s.lsp.clients[1]
  local ai_name, ai_status = require("lcars.ai").label()
  local py = s.python
  local git = require("lcars.git")
  local branch = git.branch()
  local tests = s.tests.status
  local beat = (tick_n % 2 == 0) and "●" or "○"

  local function on(v, ok_text, dim_text)
    if v then
      return ok_text, "LcarsDashOnline", "green"
    end
    return dim_text, "LcarsDashOffline", "gray3"
  end

  local rows = {
    { "LCARS INTERFACE", s.red_alert and "RED ALERT" or ("ONLINE " .. beat), s.red_alert and "LcarsDashAlert" or "LcarsDashOnline", s.red_alert and "red_bright" or "green" },
    { "NEOVIM " .. require("lcars.system").nvim_version(), "ONLINE", "LcarsDashOnline", "green" },
    { "PYTHON " .. (py.version or ""), on(py.exe, py.venv and ("READY · " .. py.venv:upper()) or "READY", "NOT FOUND") },
    { "LANGUAGE ANALYSIS", lsp and lsp:upper() or "STANDBY", lsp and "LcarsDashOnline" or "LcarsDashStandby", lsp and "green" or "amber" },
    { "GIT TELEMETRY", branch and branch:upper() or "NO REPOSITORY", branch and "LcarsDashOnline" or "LcarsDashOffline", branch and "green" or "gray3" },
    { "VALIDATION", tests == "UNKNOWN" and "NO DATA" or (require("lcars.tests").label() or tests),
      tests == "PASS" and "LcarsDashOnline" or (tests == "FAIL" and "LcarsDashAlert" or "LcarsDashOffline"),
      tests == "PASS" and "green" or (tests == "FAIL" and "red_bright" or "gray3") },
    { "AI ASSISTANCE", ai_name and (ai_name .. " " .. ai_status) or "OFFLINE",
      (ai_name and ai_status ~= "OFFLINE") and "LcarsDashOnline" or "LcarsDashOffline", (ai_name and ai_status ~= "OFFLINE") and "green" or "gray3" },
    { "DEBUGGER", s.dap.available and s.dap.status or "NOT INSTALLED", s.dap.available and "LcarsDashStandby" or "LcarsDashOffline", s.dap.available and "amber" or "gray3" },
  }
  local items = {}
  for i, r in ipairs(rows) do
    local label, value, vhl, light = r[1], r[2], r[3], r[4]
    local segs = {
      seg(" ", "LcarsBlock" .. cap(light)),
      seg("  " .. pad(label, 26), "LcarsDashLabel"),
    }
    local w = 1 + 2 + 26 + util.width(value)
    segs[#segs + 1] = seg(string.rep("·", math.max(1, CONTENT - w - 3)) .. "  ", "LcarsDashDots")
    segs[#segs + 1] = seg(value, vhl)
    items[#items + 1] = crow(fc.side1, i == #rows and "SYSTEMS" or nil, segs, i == #rows and { padding = 1 } or nil)
  end
  return items
end

local function cascade_items()
  if state.config.data_cascade == false then
    return {}
  end
  if #cascade == 0 then
    rand_cascade()
  end
  local fc = frame_colors()
  local items = {}
  for i, line in ipairs(cascade) do
    items[#items + 1] = crow(fc.side2, i == #cascade and "DATA" or nil,
      { seg("   " .. pad(line, CONTENT - 3), i % 2 == 0 and "LcarsDashCascade" or "LcarsDashCascadeHi") },
      i == #cascade and { padding = 1 } or nil)
  end
  return items
end

local function recent_files(limit)
  local out, seen = {}, {}
  for _, f in ipairs(vim.v.oldfiles or {}) do
    if #out >= limit then
      break
    end
    if f:sub(1, 1) == "/" and not seen[f] and not f:match("/%.git/") and util.exists(f) then
      seen[f] = true
      out[#out + 1] = f
    end
  end
  return out
end

local function key_items()
  local fc = frame_colors()
  local has_session = false
  pcall(function()
    has_session = require("persistence").current and util.exists(require("persistence").current()) or false
  end)
  local keys = {
    { key = "f", desc = "SEARCH FILES", action = ":lua Snacks.dashboard.pick('files')" },
    { key = "r", desc = "RECENT FILES", action = ":lua Snacks.dashboard.pick('oldfiles')" },
    { key = "g", desc = "SEARCH TEXT", action = ":lua Snacks.dashboard.pick('live_grep')" },
    { key = "p", desc = "PROJECTS", action = ":lua Snacks.picker.projects()" },
    { key = "t", desc = "GIT STATUS", action = ":lua Snacks.picker.git_status()", enabled = state.git.available },
    { key = "s", desc = "RESTORE SESSION", section = "session", enabled = has_session },
    { key = "o", desc = "LCARS CONTROL CENTER", action = ":LCARS" },
    { key = "l", desc = "PLUGIN MANAGER", action = ":Lazy" },
    { key = "c", desc = "CONFIGURATION", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
    { key = "q", desc = "TERMINATE SESSION", action = ":qa" },
  }
  local out = {}
  for _, k in ipairs(keys) do
    if k.enabled ~= false then
      out[#out + 1] = k
    end
  end
  -- two columns of pills
  local items = {}
  local col_w = math.floor(CONTENT / 2)
  for i = 1, #out, 2 do
    local a, b = out[i], out[i + 1]
    local segs = {}
    local function one(k, color)
      local t = pill(color, k.key)
      t[#t + 1] = seg("  " .. k.desc, "LcarsDashLabel")
      local w = 0
      for _, sgm in ipairs(t) do
        w = w + util.width(sgm[1])
      end
      t[#t + 1] = seg(string.rep(" ", math.max(1, col_w - w)), "LcarsGap")
      return t
    end
    extend(segs, one(a, a.key == "q" and "salmon" or "peach"))
    if b then
      extend(segs, one(b, b.key == "q" and "salmon" or "lilac"))
    end
    local last = i + 2 > #out
    local item = crow(fc.side3, last and "DATABASE" or nil, segs, last and { padding = 1 } or nil)
    item.key = a.key
    item.action = a.action
    item.section = a.section
    items[#items + 1] = item
    if b then
      -- the second key of the row needs its own (invisible) item to bind the key
      items[#items + 1] = { key = b.key, action = b.action, section = b.section, hidden = true, text = {} }
    end
  end
  return items
end

local function record_items()
  local fc = frame_colors()
  local files = recent_files(5)
  local items = {}
  if #files == 0 then
    items[#items + 1] = crow(fc.side4, "RECORDS", { seg("   NO RECENT RECORDS", "LcarsDashOffline") }, nil, { row = 0, bottom = true })
    return items
  end
  for i, f in ipairs(files) do
    local rel = vim.fn.fnamemodify(f, ":~")
    local dir = vim.fn.fnamemodify(rel, ":h")
    local name = vim.fn.fnamemodify(rel, ":t")
    local maxdir = CONTENT - 6 - util.width(name) - 4
    if util.width(dir) > maxdir then
      dir = "…" .. dir:sub(-(maxdir - 1))
    end
    local segs = pill("amber", tostring(i))
    segs[#segs + 1] = seg("  " .. dir .. "/", "LcarsDashDim")
    segs[#segs + 1] = seg(name, "LcarsDashValue")
    local last = i == #files
    local item = crow(fc.side4, last and "RECORDS" or nil, segs, nil, last and { row = 0, bottom = true } or nil)
    item.key = tostring(i)
    item.action = function()
      vim.cmd("edit " .. vim.fn.fnameescape(f))
    end
    items[#items + 1] = item
  end
  return items
end

local function footer_items()
  local s, fc = state, frame_colors()
  local ok, lazy = pcall(require, "lazy")
  local stats = ok and lazy.stats() or { loaded = 0, count = 0, startuptime = 0 }
  local ms = math.floor((stats.startuptime or 0) * 100 + 0.5) / 100
  local text = string.format("%d/%d SUBSYSTEMS LOADED · %sms · UP %s", stats.loaded, stats.count, ms, util.fmt_duration(s.uptime()))
  -- sweeping activity indicator: one lit segment travels along a short bar
  local l = { seg(" ", "LcarsGap") }
  extend(l, corner_segs(fc.bottom, R_ROWS - 1, true))
  extend(l, { blk(fc.bottom, pad(" DECK 01", SIDE - R_COLS + GAP + 2)), seg(" " .. text .. " ", "LcarsText" .. cap(fc.bottom)) })
  local used = 1 + SIDE + GAP + 2 + util.width(text) + 2
  local n = math.max(3, math.min(8, math.floor((WIDTH - used - 4) / 2)))
  for i = 1, n do
    local lit = ((tick_n % n) + 1) == i
    l[#l + 1] = seg(" ", lit and "LcarsBlock" .. cap(fc.accent) or "LcarsBlockGray2")
    l[#l + 1] = seg(" ", "LcarsGap")
  end
  used = used + n * 2
  local fill = math.max(2, WIDTH - used - 1)
  l[#l + 1] = blk(fc.bottom, string.rep(" ", fill))
  l[#l + 1] = capr(fc.bottom)
  return { elbow_row(fc.bottom, WIDTH - (1 + SIDE + 1) - 1, false), { text = l } }
end

--- Full LCARS section list (called on every dashboard render).
function M.sections()
  local out = {}
  vim.list_extend(out, header_items())
  vim.list_extend(out, status_items())
  vim.list_extend(out, cascade_items())
  vim.list_extend(out, key_items())
  vim.list_extend(out, record_items())
  vim.list_extend(out, footer_items())
  return out
end

--- Installed as opts.dashboard.sections in the Snacks plugin spec.
function M.sections_dispatch(dash)
  if state.enabled and state.config.dashboard ~= false then
    if dash and dash.opts then
      if not dash.opts._lcars_width then
        dash.opts._lcars_width = dash.opts.width or 60
      end
      dash.opts.width = WIDTH
    end
    return M.sections()
  end
  if dash and dash.opts and dash.opts._lcars_width then
    dash.opts.width = dash.opts._lcars_width
    dash.opts._lcars_width = nil
  end
  return vim.deepcopy(DEFAULT_SECTIONS)
end

function M.visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then
      return true
    end
  end
  return false
end

function M.update()
  if not (package.loaded["snacks"] and Snacks.dashboard) then
    return
  end
  if M.visible() then
    pcall(Snacks.dashboard.update)
  end
end

M.refresh = util.debounce(200, M.update)

local function boot()
  if state.boot.done or boot_timer:running() then
    return
  end
  state.boot.phase = 1
  local function step()
    if not state.enabled then
      state.boot.done = true
      return
    end
    if state.boot.phase >= #BOOT then
      state.boot.done = true
      M.update()
      return
    end
    state.boot.phase = state.boot.phase + 1
    M.update()
    boot_timer:start(140, step, false)
  end
  boot_timer:start(140, step, false)
end

function M.on_tick()
  if state.config.data_cascade == false or not state.boot.done then
    return
  end
  if M.visible() then
    tick_n = tick_n + 1
    if tick_n % 2 == 0 then
      rand_cascade()
    end
    M.update()
  end
end

---@param group integer
function M.setup(group)
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardOpened",
    callback = function()
      if state.config.dashboard ~= false then
        boot()
      end
    end,
  })
  if M.visible() then
    boot()
    M.update()
  end
end

function M.teardown()
  pcall(require("lcars.graphics").clear)
  boot_timer:stop()
  state.boot.done = true
  M.update()
end

return M
