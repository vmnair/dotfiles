return {
  'stevearc/oil.nvim',
  opts = {},
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function ()
    require("oil").setup{
        columns = { "icon"},
        default_file_explorer = true,
        keymaps = {
            ["<C-h"] = false,
            ["<M-h>"] = "actions.select.split",
        },
        view_options = {
            show_hidden = true,
        },
    }
    --keymaps
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
  end,
}
