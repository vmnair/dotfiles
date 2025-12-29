-- lsp-config.lua
-- Mason & mason-lspconfig is also setup here
-- Need to setup in the order of: mason.nvim, mason-lspconfig.nvim followed by
-- nvim-lspconfig

return {

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
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
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lspconfig = require("lspconfig")
			local map = vim.keymap.set
			local ok, blink = pcall(require, "blink.cmp")
			local capabilities = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

			-- Lua language server configuration
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							-- get the language server to recognize the `vim` global
							globals = { "vim" },
						},
					},
				},
			})

			-- clangd language server configuration
			lspconfig.clangd.setup({
				capabilities = capabilities,
				cmd = { "clangd", "--compile-commands-dir=build" },
				filetypes = { "c", "cpp" },
				root_dir = function(fname)
					return lspconfig.util.root_pattern("CMakeLists.txt", "build/compile_commands.json")(fname)
				end,
			})

			-- gopls language server configuration with auto-formatting
			lspconfig.gopls.setup({
				capabilities = capabilities,
				on_attach = function(_, bufnr)
					-- Enable formatting on save
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ async = false })
						end,
					})
				end,
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git"),
				settings = {
					gopls = {
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
						},
					},
				},
			})

			-- cmake language server configuration
			lspconfig.cmake.setup({
				capabilities = capabilities,
				filetypes = { "cmake" },
			})

			-- bash language server configuration
			lspconfig.bashls.setup({
				capabilities = capabilities,
				filetypes = { "sh", "bash" },
			})

			-- texlab language server configuration (LaTeX)
			lspconfig.texlab.setup({
				capabilities = capabilities,
				settings = {
					texlab = {
						build = {
							executable = "latexmk",
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
							onSave = true,
						},
						forwardSearch = {
							executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
							args = { "-g", "%l", "%p", "%f" },
						},
					},
				},
			})

			-- pyright language server configuration
			lspconfig.pyright.setup({
				capabilities = capabilities,
			})

			-- Diagnostic floating window should have rounded borders
			vim.diagnostic.config({
				float = {
					border = "double",
				},
				virtual_text = true,
			})

			-- Global mappings
			map("n", "<leader>ql", vim.diagnostic.setloclist, { desc = "Show diagnostics in location list" })
			map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
			map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })

			-- Create an autocommand when the lsp server attaches
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
					-- Buffer local mappings.
					map("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Go to declaration" })
					map("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Show hover information" })
					map("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
					map("n", "gi", vim.lsp.buf.implementation, { buffer = ev.buf, desc = "Go to implementation" })
					map("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Go to references" })
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Actions" })
					vim.keymap.set("n", "gf", function()
						vim.lsp.buf.format({ async = true })
					end, { buffer = ev.buf, desc = "Format code" })
				end,
			})
		end,
	},
	-- This is for the diagnostic signs
	vim.diagnostic.config({
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "✘",
				[vim.diagnostic.severity.WARN] = "▲",
				[vim.diagnostic.severity.HINT] = "⚑",
				[vim.diagnostic.severity.INFO] = "»",
			},
		},
	}),
}
