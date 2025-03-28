return {
  "stevearc/oil.nvim",
  opts = {},
  dependencies = { "echasnovski/mini.icons", opts = {} },
  lazy = false,
  vim.keymap.set("n", "-", "<Cmd>Oil --float<CR>", { desc = "Open parent directory in Oil." }),
}
