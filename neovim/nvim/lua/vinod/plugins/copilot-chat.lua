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
				height = 0.5, -- 51% of screen height
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

			-- Add Ollama provider
			providers = {
				ollama = {
					prepare_input = function(chat_input, opts)
						return require("CopilotChat.config.providers").copilot.prepare_input(chat_input, opts)
					end,
					prepare_output = function(output)
						return require("CopilotChat.config.providers").copilot.prepare_output(output)
					end,
					get_models = function(headers)
						local response, err =
							require("CopilotChat.utils.curl").get("http://localhost:11434/v1/models", {
								headers = headers,
								json_response = true,
							})
						if err then
							error(err)
						end
						return vim.tbl_map(function(model)
							return {
								id = model.id,
								name = model.id,
							}
						end, response.body.data)
					end,
					embed = function(inputs, headers)
						local response, err =
							require("CopilotChat.utils.curl").post("http://localhost:11434/v1/embeddings", {
								headers = headers,
								json_request = true,
								json_response = true,
								body = {
									input = inputs,
									model = "all-minilm",
								},
							})
						if err then
							error(err)
						end
						return response.body.data
					end,
					get_url = function()
						return "http://localhost:11434/v1/chat/completions"
					end,
				},
			},
		},

		-- Lazy-loaded keymaps
		keys = {
			{ "<leader>cco", ":CopilotChat<CR>", desc = "Open Copilot Chat" },
			{ "<leader>cct", ":CopilotChatToggle<CR>", desc = "Toggle Copilot Chat" },
			{ "<leader>ccx", ":CopilotChatClose<CR>", desc = "Close Copilot Chat" },
			{ "<leader>ccr", ":CopilotChatReset<CR>", desc = "Reset Current Chat" },
			{ "<leader>ccs", ":CopilotChatSave ", desc = "Save Chat" },
			{ "<leader>ccl", ":CopilotChatLoad ", desc = "Load Chat" },
			{ "<leader>ccm", ":CopilotChatModels<CR>", desc = "Select Chat Model" },
			{
				"<leader>ob",
				function()
					require("vinod.ollama_integration").send_buffer_context()
				end,
				desc = "Send Buffer to Chat",
			},
			{
				"<leader>os",
				function()
					require("vinod.ollama_integration").send_visual_selection()
				end,
				mode = "v",
				desc = "Send Selection to Chat",
			},
		},
	},
}
