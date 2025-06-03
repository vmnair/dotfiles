return {
  "stevearc/oil.nvim",
  opts = {},
  dependencies = { "echasnovski/mini.icons", opts = {} },
  lazy = false,
  -- Open the current file's directory in Oil in a floating window
  vim.keymap.set("n", "-", "<Cmd>Oil --float<CR>", { desc = "Open parent directory in Oil." }),

  --Show hidden files by default
  config = function(_, opts)
    require("oil").setup({
      view_options = {
        show_hidden = false,
      },
      float = {
        max_width = 0.9,
        max_height = 0.9,
      },
      keymaps = {
        ["<C-h>"] = "actions.toggle_hidden",
        ["<C-l>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-v>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
      },
    })
  end,
}
