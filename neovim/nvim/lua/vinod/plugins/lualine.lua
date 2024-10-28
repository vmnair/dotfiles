-- lualine.lua
-- Load and configure 'lualine'

-- get currently selected model

local gen = require("vinod.plugins.gen-nvim")
local function get_gen_model()
	return gen.opts.model
end

--TODO: Update the model status to show the currently selected model.

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },

	config = function()
		require("lualine").setup({
			options = {
				theme = "tokyonight-night",
				--theme = 'catppuccin'
			},

			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = { "filename" },
				lualine_x = { get_gen_model },
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			refresh = {
				statusline = 1000,
			},
		})
	end,
}
