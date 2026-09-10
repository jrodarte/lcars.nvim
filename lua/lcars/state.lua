-- Central runtime state for the LCARS subsystem. Every UI component reads
-- cached values from here; collectors (python/git/lsp/...) write to it.
-- Nothing in this module performs I/O.
local M = {}

M.enabled = false
M.animating = false -- animation timer currently running
M.red_alert = false
M.focused = true
M.started = os.time() -- session start (uptime)
M.tick = 0 -- animation tick counter
M.boot = { phase = 0, done = false } -- dashboard boot sequence

---@type table config resolved by require("lcars").setup()
M.config = {}

-- Values captured on enable so disable can restore them exactly.
M.prev = {}

-- Per-session decorative identifiers.
M.ids = {}

-- Collector caches --------------------------------------------------------

M.mode = { raw = "n", label = "COMMAND MODE", short = "CMD", color = "amber" }

M.python = {
  version = nil, ---@type string?
  venv = nil, ---@type string? name of the environment
  venv_path = nil, ---@type string?
  kind = nil, ---@type string? "venv"|"conda"|"poetry"|"system"
  exe = nil, ---@type string?
  ruff = nil, ---@type boolean?
  formatter = nil, ---@type string?
}

M.git = {
  root = nil, ---@type string?
  branch = nil, ---@type string?
  worktree = false,
  modified = 0,
  staged = 0,
  untracked = 0,
  ahead = 0,
  behind = 0,
  dirty = false,
  available = false,
}

M.lsp = {
  clients = {}, ---@type string[] attached to current buffer
  busy = false, -- progress in flight
}

M.diag = { error = 0, warn = 0, info = 0, hint = 0 }

M.tests = {
  status = "UNKNOWN", ---@type "UNKNOWN"|"RUNNING"|"PASS"|"FAIL"
  passed = nil, ---@type number?
  failed = nil, ---@type number?
  total = nil, ---@type number?
  source = nil, ---@type string? "neotest"|"pytest-cache"
}

M.dap = {
  available = false,
  active = false,
  status = "STANDBY",
  breakpoints = 0,
}

M.ai = {
  available = false,
  status = "OFFLINE", ---@type "OFFLINE"|"READY"|"ACTIVE"|"BUSY"
  provider = nil, ---@type string?
  copilot = nil, ---@type string?
}

M.project = { name = nil, root = nil }

---@return number seconds
function M.uptime()
  return os.time() - M.started
end

return M
