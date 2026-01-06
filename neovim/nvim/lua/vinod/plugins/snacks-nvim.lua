-- stylua: ignore
return {
  "folke/snacks.nvim",
  event = "VeryLazy",
  ---@type snacks.Config
  opts = {
    animate = {
      enabled = false,         -- enable animations
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
        files = {
          hidden = true, -- show hidden files
          follow = true, -- follow symlinks
          format = "file",
        },
        -- grep = {
        --   format = "file",
        -- },
        -- buffers = {
        --   format = "file",
        -- },
        explorer = {
          replace_netrw = true,
          enabled = true,
          auto_close = false,
          jumb = { close = false },
          format = "file",
          hidden = true,
        },
      },

      ---@class snacks.picker.formatters.Config
      formatters = {
        text = {
          ft = nil, ---@type string? filetype for highlighting
        },
        file = {
          filename_first = true, -- display filename before the file path
          truncate = 40,         -- truncate the file path to (roughly) this length
          filename_only = false, -- only show the filename
          icon_width = 2,        -- width of the icon (in characters)
          git_status_hl = true,  -- use the git status highlight group for the filename
        },
        selected = {
          show_always = false, -- only show the selected column when there are multiple selections
          unselected = true,   -- use the unselected icon for unselected items
        },
        severity = {
          icons = true,  -- show severity icons
          level = false, -- show severity level
          ---@type "left"|"right"
          pos = "left",  -- position of the diagnostics
        },
      },

    },
    -- terminal configuration
    -- terminal = {
    --   enabled = true,
    -- },

    -- Input
    input = {
      icon = " ",
      icon_hl = "SnacksInputIcon",
      icon_pos = "left",
      prompt_pos = "title",
      win = { style = "input" },
      expand = true,
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

  config = function(_, opts)
    require("snacks").setup(opts)
    vim.ui.input = require("snacks").input
  end,

  keys = {
    { "<leader>e",  function() require("snacks").explorer() end, desc = "File Explorer" },
    { "<leader>zd", function() require("snacks").dim() end,      desc = "Toggle dim" },
    -- { "<leader>t",  function() require("snacks").terminal() end, desc = "Toggle terminal" },

  } -- keymaps for snacks.nvim
}
