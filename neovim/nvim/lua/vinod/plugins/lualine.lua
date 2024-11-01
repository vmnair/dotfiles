-- lualine.lua
-- Load and configure 'lualine'

-- get currently selected model

--TODO: Update the model status to show the currently selected model.
local function get_current_ollama_model()
	local gen_config = require("vinod.plugins.gen-nvim")
	return gen_config.opts.model
end

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
					{ get_current_ollama_model, icon = "", color = { fg = "#ff9e64", gui = "bold" } },
				},
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			refresh = { statusline = 1000 },
		})
	end,
}
