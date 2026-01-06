-- mini.nvim main library
return {
	"nvim-mini/mini.nvim",
	version = "*",
	config = function()
		require("mini.ai").setup()
		require("mini.icons").setup()
		require("mini.cmdline").setup({
			autocomplete = { enable = true, delay = 0 },
			autocorrect = { enable = true },
			autopeek = { enable = true, n_context = 1 },
		})
		require("mini.statusline").setup()
		require("mini.pairs").setup()
		require("mini.surround").setup()
	end,
}
