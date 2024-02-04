-- toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			direction = "horizontal",
      -- persist_size = false,
      -- size = 20,
			open_mapping = "<leader>t",
			auto_scroll = true,
			float_opts = {
				border = "single",
			},
		})
	end,
}
