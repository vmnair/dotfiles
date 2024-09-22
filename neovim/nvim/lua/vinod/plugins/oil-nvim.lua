return {
	"stevearc/oil.nvim",
	opts = {},
	-- Optional dependencies
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			columns = { "icon" },
			default_file_explorer = true,
			delete_to_trash = true, -- needs full disk access on mac
			skip_confirm_for_simple_edits = true,
			keymaps = {
				["<C-h>"] = false,
				["<M-h>"] = "actions.select.split",
			},
			view_options = {
				show_hidden = false,
				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, ".")
				end,
				is_always_hidden = function(name, _)
					return name == ".." or name == ".git" or name == "*.proj"
				end,
			},
			win_options = {
				wrap = true,
			},
		})
		--keymaps
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
}
