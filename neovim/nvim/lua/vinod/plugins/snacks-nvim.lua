-- stylua: ignore
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {

    animate = {
      enabled = true,          -- enable animations
      duration = 200,          -- duration of the animation in ms
      easing = "in-out-cubic", -- easing function for the animation
      -- easing = "linear", -- linear animation
      -- easing = "in-out-quad", -- quadratic animation
      -- easing = "in-out-sine", -- sine animation
    },
    -- dim options
    dim = {
      enabled = true,
      highlight = "folded", -- use a different highlight group
      priority = 80,        -- lower the priority
      min_size = 3,         -- larger minimum scope size
    },
    indent = {
      priority = 1,
      enabled = true,       -- enable indent guides
      char = "│",
      only_scope = false,   -- only show indent guides of the scope
      only_current = false, -- only show indent guides in the current window
      hl = "SnacksIndent", ---@type string|string[] hl groups for indent guides
    },
    -- picker configuration
    picker = {
      sources = {
        explorer = {
          replace_netrw = true,
          enabled = true,
          auto_close = false,
          jumb = { close = false },
        }
      }
    },
    -- terminal configuration
    terminal = {
      enabed = true,

    },


    -- notifier configuration
    notifier = {
      timeout = 3000, -- default timeout in ms
      width = { min = 40, max = 0.4 },
      height = { min = 1, max = 0.6 },
      -- editor margin to keep free. tabline and statusline are taken into account automatically
      margin = { top = 0, right = 1, bottom = 0 },
      padding = true,              -- add 1 cell of left/right padding to the notification window
      sort = { "level", "added" }, -- sort by level and time
      -- minimum log level to display. trace is the lowest
      -- all notifications are stored in history
      level = vim.log.levels.trace,
      icons = {
        error = " ",
        warn = " ",
        info = " ",
        debug = " ",
        trace = " ",
      },
      keep = function(notif)
        return vim.fn.getcmdpos() > 0
      end,
      -- -@type snacks.notifier.style
      style = "bordered",
      top_down = false,   -- place notifications from bottom to top
      date_format = "%r", -- time format for notifications
      -- format for footer when more lines are available
      -- `%d` is replaced with the number of lines.
      -- only works for styles with a border
      ---@type string|boolean
      more_format = " ↓ %d lines ",
      refresh = 50, -- refresh at most every 50ms
    },

  },

  keys = {
    { "<leader>e",  function() require("snacks").explorer() end, desc = "File Explorer" },
    { "<leader>zd", function() require("snacks").dim() end,      desc = "Toggle dim" },
    { "<leader>t",  function() require("snacks").terminal() end, desc = "Toggle terminal" },
  } -- keymaps for snacks.nvim

}
