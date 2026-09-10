-- :checkhealth lcars
local M = {}

local function has_plugin(name)
  local ok, cfg = pcall(require, "lazy.core.config")
  return ok and cfg.spec and cfg.spec.plugins[name] ~= nil
end

function M.check()
  local health = vim.health
  health.start("lcars.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error("Neovim 0.10 or newer is required")
  end

  if vim.o.termguicolors then
    health.ok("termguicolors is set")
  else
    health.warn("termguicolors is off; LCARS colours need truecolor")
  end

  local st = require("lcars.state")
  if next(st.config) then
    health.ok("setup() called (" .. (st.enabled and "LCARS ACTIVE" or "LCARS OFFLINE") .. ")")
  else
    health.warn("require('lcars').setup() has not run; import 'lcars.plugins' in your lazy spec")
  end

  local function plugin(name, what, required)
    if has_plugin(name) then
      health.ok(name .. ": " .. what)
    elseif required then
      health.error(name .. " missing: " .. what)
    else
      health.info(name .. " not installed: " .. what .. " (optional)")
    end
  end
  plugin("snacks.nvim", "dashboard, picker, notifications", false)
  plugin("lualine.nvim", "hidden/restored around the LCARS statusline", false)
  plugin("bufferline.nvim", "LCARS buffer strip", false)
  plugin("which-key.nvim", "<leader>v command group", false)
  plugin("trouble.nvim", "winbar symbols", false)
  plugin("gitsigns.nvim", "per-buffer hunk counts", false)
  plugin("nvim-dap", "debug segment", false)
  plugin("neotest", "test status (falls back to .pytest_cache)", false)
  plugin("avante.nvim", "AI status", false)

  if package.loaded["lazyvim"] then
    health.ok("LazyVim detected: project roots and plugin opts use LazyVim helpers")
  else
    health.info("LazyVim not detected: falling back to cwd for project root")
  end

  if vim.fn.executable("git") == 1 then
    health.ok("git executable found")
  else
    health.warn("git not found: git telemetry disabled")
  end
  health.info("Nerd Font required for the rounded segment caps (JetBrainsMono Nerd Font recommended)")
end

return M
