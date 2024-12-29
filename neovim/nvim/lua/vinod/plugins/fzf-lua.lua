return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"junegunn/fzf",
		-- build = "./install --bin",
	},
	config = function()
		-- calling `setup` is optional for customization
		require("fzf-lua").setup({})
	end,

	-- Example key mappings for fzf-lua
	vim.keymap.set("n", "<leader>ff", "require('fzf-lua').files", { desc = "Fzf Files" }),

	vim.keymap.set("n", "<leader>fb", "require('fzf-lua').buffers", { desc = "Fzf Buffers" }),

	vim.keymap.set("n", "<leader>fg", "require('fzf-lua').live_grep", { desc = "Fzf Live Grep" }),

	vim.keymap.set("n", "<leader>fh", "require('fzf-lua').help_tags", { desc = "Fzf Help Tags" }),

	--  vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"<leader>fg",
	-- 	":lua require('fzf-lua').live_grep()<CR>",
	-- 	{ noremap = true, silent = true }
	-- ),
	-- vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"<leader>fb",
	-- 	":lua require('fzf-lua').buffers()<CR>",
	-- 	{ noremap = true, silent = true }
	-- ),
	-- vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"<leader>fh",
	-- 	":lua require('fzf-lua').help_tags()<CR>",
	-- 	{ noremap = true, silent = true }
	-- ),
}
