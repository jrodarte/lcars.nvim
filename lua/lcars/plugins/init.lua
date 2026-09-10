-- lazy.nvim specs shipped with the plugin. Import them from your config:
--   { "jrodarte/lcars.nvim", import = "lcars.plugins", opts = { ... } }
-- (the same `import` mechanism LazyVim uses for its own plugin specs)
return {
  {
    "jrodarte/lcars.nvim",
    lazy = false,
    priority = 900, -- after your regular colorscheme (1000) so the previous theme is known
    opts = {},
    config = function(_, opts)
      require("lcars").setup(opts)
    end,
  },

  -- Toggle-safe dispatchers: stock Snacks behaviour while LCARS is off.
  {
    "folke/snacks.nvim",
    optional = true,
    opts = function(_, opts)
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.sections = require("lcars.dashboard").sections_dispatch
      opts.notifier = opts.notifier or {}
      opts.notifier.style = require("lcars.notifications").dispatch
    end,
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>v", group = "lcars", icon = { icon = "󱎃", color = "orange" } },
      },
    },
  },
}
