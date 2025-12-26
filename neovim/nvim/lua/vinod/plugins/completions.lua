return {
	-- Completion sources
	{
		"hrsh7th/cmp-nvim-lsp", -- completion plugin for Neovim's build-in LSP
		"hrsh7th/cmp-buffer", -- source for text in the current buffer
		"hrsh7th/cmp-path", -- source for file system paths
		"hrsh7th/cmp-cmdline", -- source for command line mode
		"hrsh7th/cmp-nvim-lsp-signature-help", -- signature help for functions
	},
	-- Snippet engine and dependencies
	{
		"L3MON4D3/LuaSnip", -- snippet engine
		event = "VeryLazy",
		version = "v2.*", -- follow latest release.
		-- build = "make install_jsregexp", -- install jsregexp (optional!).
		dependencies = {
			"saadparwaiz1/cmp_luasnip", -- source for integrating Luasnip with cmp
		},
	},
	-- nvim-cmp setup
	{
		"hrsh7th/nvim-cmp", -- Main completion engine.
		"micangl/cmp-vimtex", -- Foe vimtex completion
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				-- mapping = cmp.mapping.preset.insert({
				--
				-- 	["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
				-- 	["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
				-- 	["<C-b>"] = cmp.mapping.scroll_docs(-4),
				-- 	["<C-f>"] = cmp.mapping.scroll_docs(4),
				-- 	["<C-y>"] = cmp.mapping.complete(),
				-- 	["<C-e>"] = cmp.mapping.abort(),
				-- 	-- Accept currently selected item.
				-- 	-- Set `select` to `false` to only confirm explicitly selected items.
				-- 	["<CR>"] = cmp.mapping.confirm({ select = true }),
				--
				-- }),
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),

				sources = cmp.config.sources({
					-- { name = "copilot" },
					-- { name = "render-markdown" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "vimtex" },
					{ name = "nvim_lsp_signature_help", max_item_count = 5 },
					{
						name = "spell",
						max_item_count = 5,
						keyword_length = 3,
						option = {
							keep_all_entries = false,
							enable_in_context = function()
								return true
							end,
						},
					},
				}, {
					{ name = "buffer" },
				}),

				experimental = {
					ghost_text = false,
				},
			})

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
				matching = { disallow_symbol_nonprefix_matching = false },
			})
		end,
	},
}
