-- nvim-tree.lua

return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeOpen", "NvimTreeToggle" },
  event = "VeryLazy",
  config = function()
    require("nvim-tree").setup({
      filters = {
        dotfiles = true,
      },
    })
  end,
  vim.api.nvim_set_keymap("n", "<leader>eo", "<Cmd>NvimTreeOpen<CR>", { noremap = true, desc = "Open Explorer" }),

  vim.api.nvim_set_keymap("n", "<leader>ec", "<Cmd>NvimTreeClose<CR>", { noremap = true, desc = "Close Explorer" }),

  vim.api.nvim_set_keymap("n", "<leader>ee", "<Cmd>NvimTreeToggle<CR>", { noremap = true, desc = "Toggle Explorer" }),

  vim.api.nvim_set_keymap("n", "<leader>ef", "<Cmd>NvimTreeFocus<CR>", { noremap = true, desc = "Focus Explorer" }),
}
