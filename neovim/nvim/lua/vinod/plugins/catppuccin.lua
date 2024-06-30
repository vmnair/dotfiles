-- catppucccin.lua

return {
    "catppuccin/nvim",
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme catppuccin ]])
    end,
    opts = {
        flavor = "latte", -- latte, frappem macchiato, mocha
    },
}
