-- Kitty graphics protocol (unicode placeholders) for pixel-perfect LCARS
-- elbows.  Ghostty and kitty draw the shipped PNG corners as real
-- anti-aliased images inside ordinary buffer cells; everything else falls back
-- to the measured block glyphs in dashboard.lua.  Images are transmitted once
-- per terminal session with q=2 (no responses, so nothing leaks into input).
local M = {}

local DIACRITICS = {
  0x0305, 0x030D, 0x030E, 0x0310, 0x0312, 0x033D, 0x033E, 0x033F, 0x0346, 0x034A, 0x034B, 0x034C,
  0x0350, 0x0351, 0x0352, 0x0357, 0x035B, 0x0363, 0x0364, 0x0365, 0x0366, 0x0367, 0x0368, 0x0369,
  0x036A, 0x036B, 0x036C, 0x036D, 0x036E, 0x036F,
}
local PLACEHOLDER = 0x10EEEE

-- image ids double as the placeholder foreground colour (24-bit), see highlights.lua
M.IMAGES = {
  ["top-orange"] = 0xC0A701,
  ["top-red_bright"] = 0xC0A702,
  ["bottom-blue_muted"] = 0xC0A703,
  ["bottom-red"] = 0xC0A704,
  ["top-salmon"] = 0xC0A705,
  ["bottom-salmon"] = 0xC0A706,
}
M.COLS, M.ROWS = 6, 3

local sent = {} ---@type table<integer, boolean>
local tmux_ok ---@type boolean|nil  cached (10 s): can we pass through tmux?
local tmux_checked = 0
local tmux_client = "" -- attached tmux client; images must be re-sent when it changes
M.reason = "" -- why the last support check said yes/no (see :checkhealth lcars)

--- Inside tmux: is passthrough available and is the outer terminal capable?
local function tmux_passthrough()
  local now = vim.loop.now()
  if tmux_ok ~= nil and now - tmux_checked < 10000 then
    return tmux_ok
  end
  tmux_checked = now
  tmux_ok = false
  if vim.fn.executable("tmux") == 1 then
    local ver = (vim.fn.system({ "tmux", "-V" }) or ""):match("(%d+%.%d+)")
    local major, minor = 0, 0
    if ver then
      major, minor = ver:match("(%d+)%.(%d+)")
      major, minor = tonumber(major) or 0, tonumber(minor) or 0
    end
    local needs_option = major > 3 or (major == 3 and minor >= 3)
    local allowed = true
    if needs_option then
      local v = vim.trim(vim.fn.system({ "tmux", "show", "-gv", "allow-passthrough" }) or "")
      allowed = v == "on" or v == "all"
    end
    if not allowed then
      M.reason = "tmux " .. tostring(ver) .. ": set -g allow-passthrough on"
    else
      -- the *attached client's* terminal decides (a server may have been started elsewhere)
      local client = vim.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{client_termname} #{client_pid}" }) or "")
      local termname = client:match("^(%S+)") or ""
      local ok = termname:find("ghostty") or termname:find("kitty")
      if not ok then
        local env = vim.fn.system({ "tmux", "show-environment", "-g" }) or ""
        ok = env:match("GHOSTTY_RESOURCES_DIR=") or env:match("KITTY_WINDOW_ID=") or env:match("TERM_PROGRAM=ghostty") or env:match("TERM_PROGRAM=kitty")
      end
      tmux_ok = ok ~= nil and ok ~= false
      if client ~= tmux_client then
        tmux_client = client
        sent = {} -- new client terminal: images must be transmitted again
      end
      M.reason = tmux_ok and ("tmux client " .. termname) or ("tmux client " .. termname .. " has no kitty graphics")
    end
  else
    M.reason = "tmux binary not found"
  end
  return tmux_ok
end
local asset_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/assets/"

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

--- Does this terminal draw kitty graphics with unicode placeholders?
function M.supported()
  if vim.g.lcars_graphics == false then
    M.reason = "vim.g.lcars_graphics = false"
    return false
  end
  if #vim.api.nvim_list_uis() == 0 then
    M.reason = "no UI attached yet"
    return false -- headless (never write to /dev/tty without a UI)
  end
  if vim.env.STY then
    M.reason = "GNU screen has no passthrough"
    return false
  end
  if vim.env.TMUX then
    local ok, res = pcall(tmux_passthrough) -- tmux >= 3.3 needs `set -g allow-passthrough on`
    return ok and res or false
  end
  if vim.env.GHOSTTY_RESOURCES_DIR or vim.env.KITTY_WINDOW_ID or vim.env.KITTY_PID then
    M.reason = "terminal env"
    return true
  end
  if (vim.env.TERM or ""):find("ghostty") or (vim.env.TERM or ""):find("kitty") then
    M.reason = "TERM=" .. vim.env.TERM
    return true
  end
  -- WezTerm (as of 20240203) implements kitty graphics but not unicode
  -- placeholders: images land at the cursor and the cells show boxes, so it
  -- keeps the glyph fallback.  Set vim.g.lcars_graphics = true to force.
  if vim.g.lcars_graphics == true then
    M.reason = "forced"
    return true
  end
  local tp = vim.env.TERM_PROGRAM or ""
  local ok = tp == "ghostty" or tp == "kitty"
  M.reason = ok and ("TERM_PROGRAM=" .. tp) or ("terminal " .. (tp ~= "" and tp or (vim.env.TERM or "?")) .. " has no kitty graphics placeholders")
  return ok
end

local function tty_write(s)
  local f = io.open("/dev/tty", "w")
  if not f then
    return false
  end
  if vim.env.TMUX then
    -- tmux passthrough envelope: DCS tmux; <payload with ESC doubled> ST
    s = "\27Ptmux;" .. s:gsub("\27", "\27\27") .. "\27\\"
  end
  f:write(s)
  f:close()
  return true
end

--- Transmit one PNG (idempotent per session).
---@param key string  e.g. "top-orange"
function M.ensure(key)
  local id = M.IMAGES[key]
  if not id or sent[id] then
    return id ~= nil and sent[id]
  end
  local f = io.open(asset_dir .. "elbow-" .. key .. ".png", "rb")
  if not f then
    return false
  end
  local data = f:read("*a")
  f:close()
  local b64 = vim.base64.encode(data)
  local out, pos, first = {}, 1, true
  while pos <= #b64 do
    local chunk = b64:sub(pos, pos + 4095)
    pos = pos + 4096
    local more = pos <= #b64 and 1 or 0
    local ctrl = (first and string.format("a=T,f=100,U=1,q=2,i=%d,c=%d,r=%d,", id, M.COLS, M.ROWS) or "") .. "m=" .. more
    out[#out + 1] = "\27_G" .. ctrl .. ";" .. chunk .. "\27\\"
    first = false
  end
  if tty_write(table.concat(out)) then
    sent[id] = true
    return true
  end
  return false
end

--- Placeholder cells for one image row: `cols` cells referencing (row, col).
---@param key string
---@param row integer 0-based
---@return string text, string hl
function M.placeholder_row(key, row)
  local cells = {}
  for col = 0, M.COLS - 1 do
    cells[#cells + 1] = uchar(PLACEHOLDER) .. uchar(DIACRITICS[row + 1]) .. uchar(DIACRITICS[col + 1])
  end
  return table.concat(cells), "LcarsImg" .. string.format("%06X", M.IMAGES[key])
end

--- Highlight groups whose foreground encodes the image id (used by highlights.lua).
function M.highlight_groups()
  local g = {}
  for _, id in pairs(M.IMAGES) do
    g["LcarsImg" .. string.format("%06X", id)] = { fg = string.format("#%06X", id) }
  end
  return g
end

--- Forget transmitted images so the next render re-sends them (terminal changed,
--- tmux client re-attached, or the user asked for a refresh).
function M.forget()
  sent = {}
end

--- Delete transmitted images (teardown).
function M.clear()
  local out = {}
  for id in pairs(sent) do
    out[#out + 1] = string.format("\27_Ga=d,d=I,i=%d,q=2\27\\", id)
  end
  sent = {}
  if #out > 0 then
    tty_write(table.concat(out))
  end
end

return M
