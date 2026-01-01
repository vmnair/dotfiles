-- lsp-config.lua
-- Mason-lspconfig for server installation and auto-enabling
-- Server configs in nvim/lsp/*.lua, overrides in lua/vinod/config/lsp.lua

return {
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig", -- Required for config data (lsp/ files)
		},
		config = function()
			require("mason-lspconfig").setup({
				automatic_installation = false,
				ensure_installed = {
					"gopls",
					"lua_ls",
					"clangd",
					"bashls",
					"cmake",
					"texlab",
					"marksman",
					"pyright",
				},
				-- Auto-enable installed servers via vim.lsp.enable()
				automatic_enable = true,
			})
		end,
	},
}
