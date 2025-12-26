-- mini.nvim main library
return {
	"nvim-mini/mini.nvim",
	version = "*",

	config = function()
		require("mini.ai").setup()
		require("mini.align").setup()
	end,
}
