return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
			{ "ibhagwan/fzf-lua" },
		},

		build = function()
			vim.notify("Building CopilotChat...")
			vim.cmd("!make tiktoken")
		end,

		-- Configuration automatically calls setup()
		opts = {
			model = "gpt-4o",
			temperature = 0.1, -- Lower = focused, higher = creative
			window = {
				layout = "vertical", -- 'vertical', 'horizontal', 'float'
				width = 0.5, -- 50% of screen width
				height = 0.5, -- 50% of screen height
				title = function()
					return "🤖 AI Assistant (Model: " .. vim.g.copilot_chat_model .. ")"
				end,
			},
			headers = {
				user = "👤 Vinod: ",
				assistant = "🤖 Copilot: ",
				tool = "🔧 Tool: ",
			},
			separator = "━━",
			show_folds = false, -- Disable folding for cleaner look
			auto_insert_mode = true, -- Enter insert mode when opening
		},

		-- Lazy-loaded keymaps
		keys = {
			{ "<leader>cco", ":CopilotChat<CR>", desc = "Open Copilot Chat" },
			{ "<leader>cct", ":CopilotChatToggle<CR>", desc = "Toggle Copilot Chat" },
			{ "<leader>ccx", ":CopilotChatClose<CR>", desc = "Close Copilot Chat" },
			{ "<leader>ccr", ":CopilotChatReset<CR>", desc = "Reset Current Chat" },
			{ "<leader>ccs", ":CopilotChatSave ", desc = "Save Chat" },
			{ "<leader>ccl", ":CopilotChatLoad ", desc = "Load Chat" },
		},
	},
}
