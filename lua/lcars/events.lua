-- Autocmd wiring that isn't owned by one collector: colorscheme guard,
-- lazy-load hooks, resize redraws, contextual file messages.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local python_announced = false

---@param group integer
function M.setup(group)
  -- Another colorscheme loaded while LCARS is on: keep the control surfaces
  -- rendering and remember the new theme as the one to restore.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if state._switching then
        return
      end
      if state.enabled and vim.g.colors_name ~= "lcars" then
        state.prev.colorscheme = vim.g.colors_name
        require("lcars.theme").apply_ui_groups()
        require("lcars.bufferline").enable()
      end
    end,
  })

  -- Plugins that load after enable (VeryLazy) and set their own UI.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = function(ev)
      if not state.enabled then
        return
      end
      if ev.data == "lualine.nvim" then
        vim.schedule(function()
          if state.enabled then
            local lualine = package.loaded["lualine"]
            if lualine then
              pcall(lualine.hide, { place = { "statusline" }, unhide = false })
            end
            vim.o.laststatus = 3
            vim.o.statusline = require("lcars.statusline").EXPR
          end
        end)
      elseif ev.data == "bufferline.nvim" then
        vim.schedule(require("lcars.bufferline").enable)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      util.redrawstatus()
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "python",
    callback = function()
      if not python_announced then
        python_announced = true
        require("lcars.notifications").event("python-open", "PYTHON ANALYSIS SUBSYSTEM ACTIVE")
      end
    end,
  })
end

function M.teardown()
  python_announced = false
end

return M
