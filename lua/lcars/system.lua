-- System identifiers, uptime, and the :LCARSStatus floating window.
local state = require("lcars.state")
local util = require("lcars.util")
local borders = require("lcars.borders")

local M = {}

local win, buf = nil, nil
local ns = vim.api.nvim_create_namespace("lcars_status")

function M.generate_ids()
  math.randomseed(os.time() + vim.fn.getpid())
  state.ids = {
    lcars = 47,
    sys = math.random(100, 999),
    proc = math.random(1000, 9999),
    data = math.random(1, 99),
    mem = math.random(1, 99),
    int = math.random(1, 99),
    com = math.random(1, 99),
  }
end

function M.nvim_version()
  local v = vim.version()
  return string.format("%d.%d.%d", v.major, v.minor, v.patch)
end

local function val(x, fallback)
  if x == nil or x == "" then
    return fallback or "N/A"
  end
  return tostring(x)
end

--- Rows for the status window and dashboard: {label, value, hl}
function M.rows()
  local s = state
  local lsp = s.lsp.clients[1]
  local lsp_state = lsp and (s.lsp.busy and "PROCESSING" or "ONLINE") or "OFFLINE"
  local ai_name, ai_status = require("lcars.ai").label()
  local tests = s.tests.status
  local rows = {
    { section = "CORE" },
    { "NEOVIM", "ONLINE " .. M.nvim_version(), "ok" },
    { "LCARS", s.enabled and "ACTIVE" or "OFFLINE", s.enabled and "ok" or "dim" },
    { "MODE", s.mode.label, "value" },
    { "ALERT STATE", s.red_alert and "RED ALERT" or "NORMAL", s.red_alert and "err" or "ok" },
    {
      "ANIMATION",
      require("lcars.animations").enabled() and (s.focused and "RUNNING" or "PAUSED") or "DISABLED",
      "value",
    },
    { section = "PROJECT" },
    { "PROJECT", val(s.project.name), "value" },
    { "ROOT", val(s.project.root and vim.fn.fnamemodify(s.project.root, ":~")), "dim" },
    { "BRANCH", val(require("lcars.git").branch(), s.git.available and "DETACHED" or "NO REPOSITORY"), "value" },
    { "WORKTREE", s.git.available and (s.git.worktree and "YES" or "NO") or "N/A", "value" },
    {
      "GIT",
      s.git.available
          and (s.git.dirty and string.format("M%d S%d ?%d", s.git.modified, s.git.staged, s.git.untracked) or "CLEAN")
        or "N/A",
      s.git.available and (s.git.dirty and "warn" or "ok") or "dim",
    },
    { "SYNC", s.git.available and string.format("↑%d ↓%d", s.git.ahead, s.git.behind) or "N/A", "value" },
    { section = "PYTHON" },
    { "PYTHON", val(s.python.version, s.python.exe and "DETECTING" or "N/A"), "value" },
    { "ENVIRONMENT", val(s.python.venv, s.python.kind == "system" and "SYSTEM" or "NONE"), "value" },
    { "INTERPRETER", val(s.python.exe and vim.fn.fnamemodify(s.python.exe, ":~")), "dim" },
    { "RUFF", s.python.ruff and "AVAILABLE" or "N/A", s.python.ruff and "ok" or "dim" },
    { "FORMATTER", val(s.python.formatter), "value" },
    { section = "ANALYSIS" },
    { "LSP", lsp and table.concat(s.lsp.clients, ", "):upper() or "NONE", lsp and "value" or "dim" },
    { "LSP STATE", lsp_state, lsp and "ok" or "dim" },
    { "ERRORS", tostring(s.diag.error), s.diag.error > 0 and "err" or "ok" },
    { "WARNINGS", tostring(s.diag.warn), s.diag.warn > 0 and "warn" or "ok" },
    { "INFO / HINTS", string.format("%d / %d", s.diag.info, s.diag.hint), "value" },
    { section = "OPERATIONS" },
    {
      "TEST STATUS",
      tests == "UNKNOWN" and "UNKNOWN" or (require("lcars.tests").label() or tests),
      tests == "PASS" and "ok" or (tests == "FAIL" and "err" or (tests == "RUNNING" and "warn" or "dim")),
    },
    { "TEST SOURCE", val(s.tests.source, "NONE"), "dim" },
    { "DEBUGGER", s.dap.available and s.dap.status or "NOT INSTALLED", s.dap.active and "warn" or "dim" },
    { "BREAKPOINTS", s.dap.available and tostring(s.dap.breakpoints) or "N/A", "value" },
    {
      "AI ASSISTANCE",
      ai_name and (ai_name .. " " .. ai_status) or "OFFLINE",
      ai_name and (ai_status == "OFFLINE" and "dim" or "ok") or "dim",
    },
    { section = "TELEMETRY" },
    { "UPTIME", util.fmt_duration(s.uptime(), true), "value" },
    { "STARDATE", util.stardate(), "dim" },
    {
      "SYSTEM ID",
      string.format("SYS %03d · PROC %d · MEM %02d", s.ids.sys or 0, s.ids.proc or 0, s.ids.mem or 0),
      "dim",
    },
  }
  return rows
end

local HL = {
  ok = "LcarsStatusOk",
  warn = "LcarsStatusWarn",
  err = "LcarsStatusErr",
  dim = "LcarsStatusDim",
  value = "LcarsStatusValue",
}

local WIDTH = 56

local function build()
  local lines, marks = {}, {}
  local function add(text, hls)
    lines[#lines + 1] = text
    for _, h in ipairs(hls or {}) do
      marks[#marks + 1] = { #lines - 1, h[1], h[2], h[3] }
    end
  end
  add("", {})
  for _, r in ipairs(M.rows()) do
    if r.section then
      local bar = "  ▌ " .. r.section .. " " .. string.rep("─", WIDTH - 6 - #r.section)
      add(bar, { { 0, -1, "LcarsStatusSection" } })
    else
      local label, value = r[1], r[2]
      local avail = WIDTH - 8 - #label
      if vim.fn.strdisplaywidth(value) > avail then
        value = "…" .. vim.fn.strcharpart(value, vim.fn.strchars(value) - avail + 1)
      end
      local pad = WIDTH - 4 - #label - vim.fn.strdisplaywidth(value)
      local text = "    " .. label .. string.rep(" ", math.max(1, pad - 2)) .. value
      add(text, {
        { 4, 4 + #label, "LcarsStatusLabel" },
        { #text - #value, -1, HL[r[3]] or "LcarsStatusValue" },
      })
    end
  end
  add("", {})
  return lines, marks
end

local function render()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local lines, marks = build()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1], m[2], {
      end_col = m[3] == -1 and #lines[m[1] + 1] or m[3],
      hl_group = m[4],
    })
  end
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_height, win, #lines)
  end
end

function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win, buf = nil, nil
end

function M.is_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

function M.refresh_window()
  if M.is_open() then
    render()
  end
end

function M.open()
  if M.is_open() then
    return M.close()
  end
  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "lcars_status"
  local lines = build()
  local height = math.min(#lines, vim.o.lines - 4)
  local border = borders.with_hl(borders.status, "LcarsStatusBorder")
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = WIDTH,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - WIDTH) / 2),
    style = "minimal",
    border = border,
    title = { { " LCARS SYSTEM STATUS ", "LcarsStatusTitle" } },
    title_pos = "left",
    footer = { { " q · CLOSE   r · REFRESH ", "LcarsStatusDim" } },
    footer_pos = "right",
  })
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:LcarsStatusBorder"
  vim.wo[win].cursorline = false
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  map("q", M.close)
  map("<Esc>", M.close)
  map("r", function()
    require("lcars").refresh()
    render()
  end)
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(M.close)
    end,
  })
  render()
end

function M.teardown()
  M.close()
end

return M
