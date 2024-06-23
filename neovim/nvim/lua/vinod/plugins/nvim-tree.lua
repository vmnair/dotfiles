-- nvim-tree.lua

return {
    "nvim-tree/nvim-tree.lua",
    cmd = {"NvimTreeOpen", "NvimTreeToggle"},
    config = function()
        require("nvim-tree").setup({
            filters = {
                dotfiles = true,
            },
        })
    end,
    vim.api.nvim_set_keymap('n', "<leader>nn", "<Cmd>NvimTreeOpen<CR>",
    {noremap = true, desc = "Show nvim-tree"}),

    vim.api.nvim_set_keymap('n', "<leader>nc", "<Cmd>NvimTreeClose<CR>",
    {noremap = true, desc = "Close nvim-tree"}),

    vim.api.nvim_set_keymap('n', "<leader>nt", "<Cmd>NvimTreeToggle<CR>",
    {noremap = true, desc = "Togggle nvim-tree"}),


    vim.api.nvim_set_keymap('n', "<leader>nf", "<Cmd>NvimTreeFocus<CR>",
    {noremap = true, desc = "Focus nvim-tree"}),

}
