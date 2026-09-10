-- <leader>v ("Voyager") is the LCARS namespace: every LazyVim <leader>u slot
-- that the LCARS spec suggested (uL/uA/uS/uD) is already taken by LazyVim.
local M = {}

function M.setup()
  local L = require("lcars")
  local maps = {
    { "<leader>vv", L.toggle, "Toggle LCARS" },
    { "<leader>vs", L.status, "LCARS system status" },
    {
      "<leader>va",
      function()
        vim.cmd("LCARSAnimations")
      end,
      "Toggle LCARS animations",
    },
    {
      "<leader>vr",
      function()
        L.red_alert()
      end,
      "Red Alert",
    },
    { "<leader>vc", L.center, "LCARS control center" },
    { "<leader>vR", L.reload, "Reload LCARS" },
    { "<leader>vt", L.refresh, "Refresh LCARS telemetry" },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set("n", m[1], m[2], { desc = m[3], silent = true })
  end
  local ok, wk = pcall(require, "which-key")
  if ok and wk.add then
    wk.add({
      { "<leader>v", group = "lcars", icon = { icon = "󱎃", color = "orange" } },
      { "<leader>vv", icon = { icon = "", color = "orange" } },
      { "<leader>vs", icon = { icon = "", color = "yellow" } },
      { "<leader>va", icon = { icon = "", color = "yellow" } },
      { "<leader>vr", icon = { icon = "", color = "red" } },
      { "<leader>vc", icon = { icon = "", color = "purple" } },
      { "<leader>vR", icon = { icon = "", color = "grey" } },
      { "<leader>vt", icon = { icon = "", color = "cyan" } },
    })
  end
end

return M
