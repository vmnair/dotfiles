return {
  vim.api.nvim_set_keymap("n", "<leader>ai", ":!aider<CR>", { noremap = true, silent = true, desc = "aider start" }),
}
