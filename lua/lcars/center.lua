-- :LCARS control center. Uses the Snacks picker when available, else vim.ui.select.
local state = require("lcars.state")
local util = require("lcars.util")

local M = {}

local function items()
  local L = require("lcars")
  local list = {
    { "SYSTEM STATUS", "LCARS system status panel", L.status },
    {
      "SEARCH FILES",
      "Project file database",
      function()
        Snacks.picker.files()
      end,
    },
    {
      "SEARCH TEXT",
      "Full-text project search",
      function()
        Snacks.picker.grep()
      end,
    },
    {
      "PROJECTS",
      "Project database",
      function()
        Snacks.picker.projects()
      end,
    },
    {
      "GIT STATUS",
      "Working tree telemetry",
      function()
        Snacks.picker.git_status()
      end,
    },
    {
      "LAZYGIT",
      "Git control console",
      function()
        Snacks.lazygit()
      end,
    },
    {
      "RUN VALIDATION",
      "pytest in a terminal (explicit)",
      function()
        if package.loaded["neotest"] then
          require("neotest").run.run(vim.fn.getcwd())
        else
          Snacks.terminal.open({ "pytest" }, { cwd = util.root(), interactive = false })
        end
      end,
    },
    {
      "DEBUG",
      state.dap.available and "Continue / launch debugger" or "Debugger not installed",
      function()
        if state.dap.available then
          require("dap").continue()
        else
          vim.notify("DEBUGGING SUBSYSTEM NOT INSTALLED", vim.log.levels.WARN, { title = "TACTICAL" })
        end
      end,
    },
    {
      "AI ASSISTANT",
      util.has_plugin("avante.nvim") and "Toggle Avante sidebar" or "AI plugin not installed",
      function()
        if util.has_plugin("avante.nvim") then
          vim.cmd("AvanteToggle")
        else
          vim.notify("AI SUBSYSTEM NOT INSTALLED", vim.log.levels.WARN, { title = "COMPUTER" })
        end
      end,
    },
    {
      "PLUGIN MANAGER",
      "lazy.nvim",
      function()
        vim.cmd("Lazy")
      end,
    },
    {
      "THEME",
      "Colorscheme database",
      function()
        Snacks.picker.colorschemes()
      end,
    },
    {
      state.red_alert and "CANCEL RED ALERT" or "RED ALERT",
      "Toggle alert condition",
      function()
        L.red_alert()
      end,
    },
    {
      (require("lcars.animations").enabled() and "ANIMATIONS OFF" or "ANIMATIONS ON"),
      "Toggle LCARS animation",
      function()
        L.animations.toggle()
      end,
    },
    {
      "SETTINGS",
      "Open LCARS configuration",
      function()
        vim.cmd.edit(vim.fn.stdpath("config") .. "/lua/plugins/lcars.lua")
      end,
    },
    {
      "RELOAD LCARS",
      "Reload the LCARS modules",
      function()
        L.reload()
      end,
    },
    {
      "EXIT LCARS",
      "Return to the standard interface",
      function()
        L.disable()
      end,
    },
  }
  local out = {}
  for i, it in ipairs(list) do
    out[#out + 1] = {
      num = string.format("%02d", i),
      text = string.format("%02d %s %s", i, it[1], it[2]),
      label = it[1],
      desc = it[2],
      action = it[3],
    }
  end
  return out
end

function M.open()
  local list = items()
  if package.loaded["snacks"] and Snacks.picker then
    Snacks.picker.pick({
      source = "lcars_center",
      title = "LCARS CONTROL CENTER",
      items = list,
      format = function(item)
        return {
          { " " .. item.num .. " ", "LcarsCenterIdx" },
          { "  " },
          { string.format("%-18s", item.label), "LcarsCenterText" },
          { "  " .. item.desc, "LcarsCenterDesc" },
        }
      end,
      confirm = function(picker, item)
        picker:close()
        if item and item.action then
          vim.schedule(function()
            local ok, err = pcall(item.action)
            if not ok then
              vim.notify(tostring(err), vim.log.levels.ERROR, { title = "LCARS" })
            end
          end)
        end
      end,
      layout = { preset = "lcars_center" },
    })
    return
  end
  vim.ui.select(list, {
    prompt = "LCARS CONTROL CENTER",
    format_item = function(item)
      return item.num .. "  " .. item.label
    end,
  }, function(item)
    if item then
      item.action()
    end
  end)
end

return M
