-- lualine.lua

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				theme = "tokyonight-night",
			},
			--theme = 'catppuccin'

			sections = {
				lualine_a = { "mode" },
				lualine_b = { "filename" },
				lualine_c = { "branch" },
				lualine_x = {
					-- 	{
					-- 		function()
					-- 			return get_current_ollama_model()
					-- 		end,
					-- 		icon = "",
					-- 		color = { fg = "#ff9e64", gui = "bold" },
					-- 	},
				},
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			refresh = { statusline = 1000 },
		})
	end,
}
