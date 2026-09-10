-- Language-server and diagnostics state for the current buffer.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local progress = {} ---@type table<number, number> client_id -> in-flight count
local announced = {} ---@type table<string, boolean>
local auto_alert = false

local function special(buf)
  return not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= ""
end

function M.update_clients(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if special(buf) then
    return
  end
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if c.name ~= "copilot" and c.name ~= "null-ls" and c.name ~= "GitHub Copilot" then
      names[#names + 1] = c.name
    end
  end
  state.lsp.clients = names
end

function M.update_busy()
  local busy = false
  for _, n in pairs(progress) do
    if n > 0 then
      busy = true
      break
    end
  end
  state.lsp.busy = busy
end

function M.update_diag(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if special(buf) then
    return
  end
  local ok, counts = pcall(vim.diagnostic.count, buf)
  if not ok then
    return
  end
  local S = vim.diagnostic.severity
  state.diag.error = counts[S.ERROR] or 0
  state.diag.warn = counts[S.WARN] or 0
  state.diag.info = counts[S.INFO] or 0
  state.diag.hint = counts[S.HINT] or 0

  local ra = state.config.red_alert or {}
  if ra.automatic then
    local threshold = ra.threshold or 1
    if state.diag.error >= threshold and not state.red_alert then
      auto_alert = true
      require("lcars").red_alert(true)
    elseif state.diag.error == 0 and state.red_alert and auto_alert then
      auto_alert = false
      require("lcars").red_alert(false)
    end
  end
end

---@param group integer
function M.setup(group)
  progress = {}
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if ev.buf == vim.api.nvim_get_current_buf() then
        M.update_clients(ev.buf)
      end
      if client and not announced[client.name] and client.name ~= "copilot" then
        announced[client.name] = true
        require("lcars.notifications").event(
          "lsp-" .. client.name,
          "LANGUAGE ANALYSIS LINK ESTABLISHED · " .. client.name:upper()
        )
      end
      util.redrawstatus()
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(ev)
      progress[ev.data.client_id] = nil
      M.update_busy()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) and ev.buf == vim.api.nvim_get_current_buf() then
          M.update_clients(ev.buf)
          util.redrawstatus()
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(ev)
      local id = ev.data and ev.data.client_id
      local kind = vim.tbl_get(ev, "data", "params", "value", "kind")
      if not id or not kind then
        return
      end
      progress[id] = progress[id] or 0
      if kind == "begin" then
        progress[id] = progress[id] + 1
      elseif kind == "end" then
        progress[id] = math.max(0, progress[id] - 1)
      end
      M.update_busy()
    end,
  })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(ev)
      if ev.buf == vim.api.nvim_get_current_buf() then
        M.update_diag(ev.buf)
        util.redrawstatus()
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      M.update_clients(ev.buf)
      M.update_diag(ev.buf)
    end,
  })
  M.update_clients()
  M.update_diag()
end

function M.teardown()
  progress = {}
  auto_alert = false
end

function M.reset_announcements()
  announced = {}
end

--- "basedpyright" / "basedpyright+ruff" / nil
function M.primary()
  return state.lsp.clients[1]
end

return M
