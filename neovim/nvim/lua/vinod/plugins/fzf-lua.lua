return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	dependencies = {
		-- "nvim-tree/nvim-web-devicons",
		"echasnovski/mini.icons",
		"junegunn/fzf",
		-- build = "./install --bin",
	},
	config = function()
		-- calling `setup` is optional for customization
		require("fzf-lua").setup({
			winopts = {
				split = "belowright 10new",
				preview = {
					hidden = "nohidden",
					border = "single",
					title = false,
					layout = "horizontal",
					horizontal = "right:50%",
				},
			},
		})
	end,

	-- Key mappings
	vim.api.nvim_set_keymap(
		"n",
		"<leader>ff",
		":lua require('fzf-lua').files()<CR>",
		{ noremap = true, silent = true }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fg",
		":lua require('fzf-lua').live_grep()<CR>",
		{ noremap = true, silent = true }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fb",
		":lua require('fzf-lua').buffers()<CR>",
		{ noremap = true, silent = true }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fh",
		":lua require('fzf-lua').help_tags()<CR>",
		{ noremap = true, silent = true }
	),
	-- Search project level
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fp",
		":lua require('fzf-lua').grep_project()<CR>",
		{ noremap = true, silent = true }
	),
	-- Search for keyword under cursor
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fk",
		":lua require('fzf-lua').grep_cword()<CR>",
		{ noremap = true, silent = true }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fq",
		":lua require('fzf-lua').grep_quickfix()<CR>",
		{ noremap = true, silent = true }
	),
}
