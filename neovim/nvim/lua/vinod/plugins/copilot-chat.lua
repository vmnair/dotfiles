return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log wrapper
			-- { "nvim-telescope/telescope.nvim" },
			{ "ibhagwan/fzf-lua" },
		},

		build = "make tiktoken",
		opts = function()
			return {
				model = "gpt-4.1", -- AI model to use
				temperature = 0.1, -- Lower = focused, higher = creative
				window = {
					layout = "vertical", -- 'vertical', 'horizontal', 'float'
					width = 0.5, -- 50% of screen width
					height = 0.5, -- 50% of screen height
					title = "🤖 AI Assistant",
				},
				headers = {
					user = "👤 Vinod: ",
					assistant = "🤖 Copilot: ",
					tool = "🔧 Tool: ",
				},
				separator = "━━",
				show_folds = false, -- Disable folding for cleaner look
				auto_insert_mode = true, -- Enter insert mode when opening
			}
		end,

		vim.keymap.set("n", "<leader>cco", ":CopilotChat<CR>", { desc = "Open Copilot Chat" }),
		vim.keymap.set("n", "<leader>cct", ":CopilotChatToggle<CR>", { desc = "Open Copilot Chat" }),
		vim.keymap.set("n", "<leader>ccx", ":CopilotChatClose<CR>", { desc = "Open Copilot Chat" }),
	},
}
