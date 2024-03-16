return {
	{
		"hrsh7th/cmp-nvim-lsp", -- completion plugin
		"hrsh7th/cmp-buffer",   -- source for text in buffer
		"hrsh7th/cmp-path",     -- source for file system paths
		"hrsh7th/cmp-cmdline",  -- source for command mode 
	},

	{
		"L3MON4D3/LuaSnip",     -- snippet engine
		dependencies = {
			"saadparwaiz1/cmp_luasnip",  -- for autocompletion
			"rafamadriz/friendly-snippets", -- useful snippets
		},
	},

	{
		"hrsh7th/nvim-cmp",
		config = function()
			-- Set up nvim-cmp.
			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()

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
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "git" }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
				}, {
					{ name = "buffer" },
				}),
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
			 })
		end,
	},
}
