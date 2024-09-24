-- Github Copilot
--
vim.g.copilot_no_tab_map = true
return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter", -- what does this do ?
	config = function()
		require("copilot").setup({
			panel = {
				enabled = true,
				auto_refresh = false,
				keymap = {
					jump_prev = "[[",
					jump_next = "]]",
					accept = "<CR>",
					refresh = "gr",
					open = "<M-o",
				},
				layout = {
					position = "right", -- | top | left | right
					ratio = 0.4,
				},
			}, -- End panel

			suggestion = { -- explain this code to me line by line.
				enabled = true,
				auto_trigger = true,
				hide_during_completion = true,
				debounce = 20,
				keymap = {
					accept = "<M-l>",
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<M-c>",
				},
			}, -- Suggestions End

			filetypes = {
				c = true,
				lua = true,
				go = true,
				rust = true,
				["."] = false,
			}, -- filetypes End
		})
	end,
}
