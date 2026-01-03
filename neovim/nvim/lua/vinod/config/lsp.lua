-- lsp.lua
-- Native LSP configuration for Neovim 0.11+
-- Server enabling handled by mason-lspconfig (automatic_enable = true)

local map = vim.keymap.set

-- Set up capabilities from blink.cmp (applied to all servers)
-- This runs early so it's ready when servers start
local ok, blink = pcall(require, "blink.cmp")
if ok then
	vim.lsp.config("*", {
		capabilities = blink.get_lsp_capabilities(),
	})
end

-- Diagnostic configuration
vim.diagnostic.config({
	float = { border = "double" },
	virtual_text = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "⚑",
			[vim.diagnostic.severity.INFO] = "»",
		},
	},
})

-- Global mappings
map("n", "<leader>ql", vim.diagnostic.setloclist, { desc = "Show diagnostics in location list" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })

-- LspAttach autocommand for buffer-local settings
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		local opts = { buffer = ev.buf }
		map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
		map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show hover information" }))
		map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
		map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
		map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
		map(
			{ "n", "v" },
			"<leader>ca",
			vim.lsp.buf.code_action,
			vim.tbl_extend("force", opts, { desc = "Code Actions" })
		)
		map("n", "gf", function()
			vim.lsp.buf.format({ async = true })
		end, vim.tbl_extend("force", opts, { desc = "Format code" }))
	end,
})
