-- telescope.lua
return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim" },

        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "find buffer" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "help tags" })
        end,
    },
    -- telescope-ui-select extention
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
}
