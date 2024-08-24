-- telescope.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "find buffer" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "help tags" })

      require("telescope").setup({
        defaults = {
          layout_config = {
            vertical = { width = 0.5 },
          },
          scroll_strategy = "limit",
          mappings = {
            i = {
              ["<C-j>"] = require("telescope.actions").move_selection_next,
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
              ["<C-h>"] = "which_key",
            },
          },
          file_ignore_patterns = {
            "build",
            "lazy-lock.json",
            ".git",
            ".gitignore",
          },

          extensions = {
            {
              "nvim-telescope/telescope-ui-select.nvim",
              config = function()
                require("telescope").setup({
                  extensions = {
                    ["ui-select"] = {
                      require("telescope.themes").get_dropdown({}),
                    },
                  },
                })
                -- To get ui-select loaded and working with telescope, you need to call
                -- load_extension, somewhere after setup function:
                require("telescope").load_extension("ui-select")
              end,
            },
            -- telescope-dap.nvim
            {
              "nvim-telescope/telescope-dap.nvim",
              config = function()
                require("telescope").setup({})
                require("telescope").load_extension("dap")
              end,
            },
          },
        },
      })
    end,
  },
}
