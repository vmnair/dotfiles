local function get_ollama_model()
	local ok, gen = pcall(require, "gen")
	if not ok then
		return ""
	end

	local model = gen.model or ""
	if model ~= "" then
		return "󰚩 " .. model
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
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "filename" },
				lualine_c = { "branch" },
				lualine_x = {
					-- TODO: Add color to the model.
					{
						get_ollama_model,
						color = { fg = "FF9e64" },
					},
				},
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			refresh = { statusline = 1000 },
		})
	end,
}
