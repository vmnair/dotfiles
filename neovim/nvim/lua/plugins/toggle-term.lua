-- toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			direction = "float",
			open_mapping = "<leader>t",
			auto_scroll = true,
			float_opts = {
				border = "single",
			},
		})
	end,
}
