-- lualine.lua

-- gen.nvim integration
local function get_ollama_model()
	local ok, gen = pcall(require, "gen")
	if not ok then
		return ""
	end

	local model = gen.model or ""
	if model ~= "" then
		return "󰚩 " .. model -- Nerd font icon for AI/model
	end
	return ""
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
					{
						get_ollama_model,
						"encoding",
						"fileformat",
						"filetype",
					},
				},
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			refresh = { statusline = 1000 },
		})
	end,
}
