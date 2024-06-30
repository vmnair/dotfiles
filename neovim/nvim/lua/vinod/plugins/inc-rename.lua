--inc-rename.nvim

return {
	"smjonas/inc-rename.nvim",
	config = function()
		require("inc_rename").setup()
        -- keymap to rename word under cursor
		vim.keymap.set("n", "<leader>rn", function()
			return ":IncRename " .. vim.fn.expand("<cword>")
		end, { expr = true })
	end,
}
