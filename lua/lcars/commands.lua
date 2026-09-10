-- User commands. Registered once at setup; safe to call whether LCARS is on or off.
local M = {}

function M.setup()
  local L = require("lcars")
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end
  cmd("LCARS", function()
    L.center()
  end, { desc = "LCARS control center" })
  cmd("LCARSOn", function()
    L.enable()
  end, { desc = "Enable LCARS interface" })
  cmd("LCARSOff", function()
    L.disable()
  end, { desc = "Disable LCARS interface" })
  cmd("LCARSToggle", function()
    L.toggle()
  end, { desc = "Toggle LCARS interface" })
  cmd("LCARSStatus", function()
    L.status()
  end, { desc = "LCARS system status" })
  cmd("LCARSAnimations", function()
    local on = L.animations.toggle()
    vim.notify("ANIMATION " .. (on and "ENABLED" or "DISABLED"), vim.log.levels.INFO, { title = "LCARS" })
  end, { desc = "Toggle LCARS animations" })
  cmd("LCARSRedAlert", function()
    L.red_alert()
  end, { desc = "Toggle Red Alert" })
  cmd("LCARSReload", function()
    L.reload()
  end, { desc = "Reload LCARS modules" })
  cmd("LCARSRefresh", function()
    L.refresh()
  end, { desc = "Refresh LCARS telemetry" })
end

return M
