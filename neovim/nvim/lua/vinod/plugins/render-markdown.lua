return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "markdown_inline" },
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		render_modes = { "n", "c", "t" }, -- modes to render.
	},
}
