-- toggleterm.lua
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
      open_mapping = "<leader>tt",
      autochdir = true, -- Sync with Neovim directory
		})
	end,
}
