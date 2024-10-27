-- lualine.lua
-- Load and configure 'lualine'
return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		require("lualine").setup({
			options = {
				theme = "tokyonight-night",
				--theme = 'catppuccin'
			},
		})
	end,
}
