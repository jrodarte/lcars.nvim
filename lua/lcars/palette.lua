-- LCARS palette (Voyager-era). Every LCARS module reads colours from here;
-- no other file should contain a raw hex value.
local M = {}

M.colors = {
  -- chrome
  black = "#000000",
  panel = "#0d0d10", -- dark readout blocks
  gray1 = "#1a1a20",
  gray2 = "#2a2a34",
  gray3 = "#3c3c4a",
  gray = "#666688", -- LCARS "gray" (blue-tinted)
  muted = "#8a8aa4",
  text_dim = "#b4b4c4",
  text = "#ececf2",
  white = "#f5f6fa",

  -- warm family
  orange = "#ff9900",
  amber = "#ffcc66",
  gold = "#ffaa00",
  peach = "#ffcc99",
  almond = "#ffaa90",
  salmon = "#ff8866",
  tomato = "#ff5555",
  red = "#dd4444",
  red_bright = "#ff2200",
  pink = "#cc6699",

  -- cool family
  lilac = "#cc99ff",
  lavender = "#ddbbff",
  violet = "#9966cc",
  blue = "#7788ff",
  blue_muted = "#5566aa",
  sky = "#9999ff",
  ice = "#88ccff",

  -- status
  green = "#33cc99",
  green_dark = "#00ab72",
}

-- Semantic roles. Modules should prefer these over raw colour names where a
-- role exists, so re-tinting the UI is a one-line change.
M.roles = {
  brand = "orange",
  heartbeat = "amber",
  project = "peach",
  git = "lilac",
  python = "sky",
  lsp = "ice",
  tests = "green",
  ai = "violet",
  dap = "salmon",
  position = "almond",
  time = "gold",
  uptime = "gray",
  filetype = "blue_muted",
  rail = "gray2",
}

M.modes = {
  n = { color = "amber", label = "COMMAND MODE", short = "CMD" },
  no = { color = "amber", label = "OPERATOR", short = "OP" },
  i = { color = "peach", label = "DATA ENTRY", short = "INS" },
  v = { color = "lavender", label = "SELECTION", short = "SEL" },
  V = { color = "lavender", label = "LINE SELECT", short = "SEL" },
  ["\22"] = { color = "lavender", label = "BLOCK SELECT", short = "SEL" },
  s = { color = "lavender", label = "SELECT", short = "SEL" },
  S = { color = "lavender", label = "SELECT", short = "SEL" },
  c = { color = "blue", label = "LCARS COMMAND", short = "CMD" },
  R = { color = "tomato", label = "OVERRIDE", short = "OVR" },
  r = { color = "tomato", label = "PROMPT", short = "PRM" },
  t = { color = "violet", label = "TERMINAL", short = "TRM" },
  nt = { color = "violet", label = "TERMINAL", short = "TRM" },
}

M.filetypes = {
  python = "PYTHON MODULE",
  json = "STRUCTURED DATA",
  jsonc = "STRUCTURED DATA",
  yaml = "CONFIGURATION MATRIX",
  toml = "CONFIGURATION MATRIX",
  sql = "DATABASE QUERY",
  markdown = "DOCUMENT ARCHIVE",
  vimwiki = "DOCUMENT ARCHIVE",
  sh = "SYSTEM COMMAND SCRIPT",
  bash = "SYSTEM COMMAND SCRIPT",
  zsh = "SYSTEM COMMAND SCRIPT",
  dockerfile = "CONTAINER SPECIFICATION",
  lua = "SYSTEM SCRIPT",
  vim = "SYSTEM SCRIPT",
  html = "DISPLAY TEMPLATE",
  css = "DISPLAY STYLE",
  javascript = "INTERFACE SCRIPT",
  typescript = "INTERFACE SCRIPT",
  gitcommit = "COMMIT RECORD",
  requirements = "DEPENDENCY MANIFEST",
  text = "TEXT RECORD",
  help = "REFERENCE ARCHIVE",
  Avante = "AI SUBSYSTEM",
  AvanteInput = "AI SUBSYSTEM",
  ["snacks_dashboard"] = "COMPUTER ACCESS",
}

---@param name string
---@return string
function M.get(name)
  return M.colors[name] or M.colors[M.roles[name] or ""] or name
end

return M
