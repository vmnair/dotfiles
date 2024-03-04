-- catppucccin.lua



return { "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
        -- vim.cmd([[colorscheme catppuccin]])
        vim.cmd.colorscheme("catppuccin")
    end,
    opts = {
        flavor = "macchiato", -- latte, frappem macchiato, mocha
    }

}

