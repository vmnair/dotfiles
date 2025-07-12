-- See: https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat-v2.lua

local prompts = {
	-- Code related prompts
	Explain = "Please explain how the following code works.",
	Review = "Please review the following code and provide suggestions for improvement.",
	Tests = "Please explain how the selected code works, then generate unit tests for it.",
	Refactor = "Please refactor the following code to improve its clarity and readability.",
	FixCode = "Please fix the following code to make it work as intended.",
	FixError = "Please explain the error in the following text and provide a solution.",
	BetterNamings = "Please provide better names for the following variables and functions.",
	Documentation = "Please provide documentation for the following code.",
	-- SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
	-- SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
	-- Text related prompts
	Summarize = "Please summarize the following text.",
	Spelling = "Please correct any grammar and spelling errors in the following text.",
	Wording = "Please improve the grammar and wording of the following text.",
	Concise = "Please rewrite the following text to make it more concise.",
}

-- Plugin setup and various configurations
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log wrapper
			{ "nvim-telescope/telescope.nvim" },
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		event = "VeryLazy",
		opts = {
			debug = false, -- Enable debugging
			show_help = true,
			question_header = "## Vinod ", -- Header to use for user questions
			answer_header = "## Copilot ", -- Header to use for AI answers
			error_header = "## Error ", -- Header to use for errors
			separator = "───", -- Separator to use in chat
			auto_follow_cursor = false, -- Auto-follow cursor in chat
			auto_insert_mode = false, -- Automatically enter insert mode when opening window and if auto follow cursor is enabled on new prompt
			chat_autocomplete = true,
			-- window = {
			--   layout = "float",
			--   -- relative = "cursor",
			--   -- width = 0.8,
			--   -- height = 0.4,
			--   -- row = 1,
			-- },
		},

		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")
			-- Use unnamed register for the selection
			opts.selection = select.unnamed

			chat.setup(opts)
			-- Setup the CMP integration
			--require("CopilotChat.integrations.cmp").setup()

			-- Ask CopilotChat regarding visually selected entry
			vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
				chat.ask(args.args, { selection = select.visual })
			end, { nargs = "*", range = true }) -- End of CopilotChatVisual

			-- CopilotChatBuffer: Select entire buffer
			vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
				chat.ask(args.args, { selection = select.buffer })
			end, { nargs = "*", range = true }) -- end of CopilotChatBuffer

			-- Inline chat with Copilot
			vim.api.nvim_create_user_command("CopilotChatInline", function(args)
				chat.ask(args.args, {
					selection = select.visual,
					window = {
						layout = "float",
						relative = "cursor",
						width = 1,
						height = 0.4,
						row = 1,
					},
				})
			end, { nargs = "*", range = true }) -- End CopilotChatInline

			-- Custom buffer for CopilotChat
			-- Autocommand to configure buffers matching the pattern "copilot-*"
			-- When entering such a buffer, it enables both relative and
			-- absolute line numbers. Additionally, if the buffer's
			-- filetype is "copilot-chat", it changes the filetype to "markdown".
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "copilot-*",
				callback = function()
					vim.opt_local.relativenumber = false
					vim.opt_local.number = false
					-- Get current filetype and set it to markdown if the current
					-- filetype is copilot-chat
					local ft = vim.bo.filetype
					if ft == "copilot-chat" then
						vim.bo.filetype = "markdown"
					end
				end,
			}) -- End of CopilotChatCustom Buffer
		end,

		mappings = {
			submit_prompt = {
				normal = "<leader>s",
				insert = "<C-s>",
			},
		},

		-- explain this
		keys = {
			-- Show help actions with telescope
			{
				"<leader>cch",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.help_actions())
				end,
				desc = "CopilotChat - Help actions",
			},
			-- Show prompts actions with telescope
			{
				"<leader>ccp",
				function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
				end,
				desc = "CopilotChat - Prompt actions",
			},
			-- Code related commands
			{ "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
			{ "<leader>ccr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
			{ "<leader>ccR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
			{ "<leader>ccn", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
			{ "<leader>cco", "<cmd>CopilotChatOptimize<cr>", desc = "CopilotChat - Optimize" },
			{ "<leader>ccd", "<cmd>CopilotChatDoc<cr>", desc = "CopilotChat - Add Docs" },
			-- Chat with Copilot in visual mode
			{
				"<leader>ccv",
				"<Cmd>CopilotChatVisual<Cr>",
				mode = "x",
				desc = "CopilotChat - Visually selected code review in vertical split",
			},
			{
				"<leader>ccx",
				"<Cmd>CopilotChatInline<Cr>",
				mode = "x",
				desc = "CopilotChat - Inline chat",
			},
			-- Custom input for CopilotChat
			{
				"<leader>cci",
				function()
					local input = vim.fn.input("Ask Copilot: ")
					if input ~= "" then
						vim.cmd("CopilotChat " .. input)
					end
				end,
				desc = "CopilotChat - Ask input",
			},
			-- Generate commit message based on the git diff
			{
				"<leader>ccm",
				"<cmd>CopilotChatCommit<cr>",
				desc = "CopilotChat - Generate commit message for all changes",
			},
			{
				"<leader>ccM",
				"<cmd>CopilotChatCommitStaged<cr>",
				desc = "CopilotChat - Generate commit message for staged changes",
			},
			-- Quick chat with Copilot
			{
				"<leader>ccq",
				function()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						vim.cmd("CopilotChatBuffer " .. input)
					end
				end,
				desc = "CopilotChat - Quick chat",
			},
			-- Debug
			{ "<leader>ccd", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
			-- Fix the issue with diagnostic
			{ "<leader>ccf", "<cmd>CopilotChatFix<cr>", desc = "CopilotChat - Fix Diagnostic" },
			-- Coplot Chat Models
			{ "<leader>cc?", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat - Select Models" },
			-- Toggle CopilotChat
			{ "<leader>cct", "<Cmd>CopilotChatToggle<Cr>", desc = "Toggle Copilot Chat" },
		},
	},
}
