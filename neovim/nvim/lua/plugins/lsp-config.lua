-- lsp-config.lua

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "clangd", "cmake", "texlab", "marksman" },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local map = vim.keymap.set
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup({
                capabilities = capabilities
            })
            lspconfig.clangd.setup({
                capabilities = capabilities
            })

            map("n", "K", vim.lsp.buf.hover, {})
            map("n", "gD", vim.lsp.buf.declaration, {})
            map("n", "gd", vim.lsp.buf.definition, {})
            map("n", "gr", vim.lsp.buf.references, {})
            map("n", "<leader>ca", vim.lsp.buf.code_action, {})
        end,
    },
}
