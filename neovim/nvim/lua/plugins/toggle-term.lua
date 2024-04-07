-- toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			open_mapping = "<leader>tt",
			insert_mapping = true, -- Mappings active in insert mode.
			autochdir = true, -- Sync with Neovim directory
		})

		-- Set keymaps function
		function _G.set_terminal_keymaps()
			local opts = { noremap = true, silent = true }
			local map = vim.api.nvim_buf_set_keymap
			map(0, "t", "<esc>", [[<c-\><c-n>]], opts) -- escape -> normal mode
		end

		-- Set keymaps using the above function
		vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
	end,

}
