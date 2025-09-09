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

    config = function()
      -- Initialize global variable for tmux status bar
      vim.g.copilot_chat_model = vim.g.copilot_chat_model or "gpt-oss:20b"

      -- -- Function to update tmux status with current model
      -- local function update_tmux_status()
      -- 	local copilot_chat = require('CopilotChat')
      -- 	if copilot_chat and copilot_chat.config and copilot_chat.config.model then
      -- 		vim.g.copilot_chat_model = copilot_chat.config.model
      -- 		-- Write to temp file for tmux status bar
      -- 		vim.fn.system('echo "' .. copilot_chat.config.model .. '" > /tmp/copilot_current_model')
      -- 	end
      -- end
      --

      -- Function to update tmux status with current model
      local function update_tmux_status()
        local copilot_chat = require("CopilotChat")
        if copilot_chat and copilot_chat.config and copilot_chat.config.model then
          vim.g.copilot_chat_model = copilot_chat.config.model
          -- Update tmux variable directly using tmux command
          local model = copilot_chat.config.model
          local cmd =
              string.format('tmux setenv -g copilot_model "%s" && tmux refresh-client -S', model)
          vim.fn.system(cmd)
        end
      end

      -- Set up CopilotChat
      require("CopilotChat").setup({
        model = "gpt-oss:20b",
        temperature = 0.1,
        window = {
          layout = "vertical", -- 'vertical', 'horizontal', 'float'
          width = 0.5,    -- 50% of screen width
          height = 0.5,   -- 51% of screen height
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
        show_folds = false,  -- Disable folding for cleaner look
        auto_insert_mode = true, -- Enter insert mode when opening

        -- Add Ollama provider
        providers = {
          ollama = {
            prepare_input = function(chat_input, opts)
              -- Use default Copilot provider's prepare_input method
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
      })

      -- Create autocmd to update status when CopilotChat model changes
      vim.api.nvim_create_autocmd("User", {
        pattern = "CopilotChatModel",
        callback = update_tmux_status,
        desc = "Update tmux status when CopilotChat model changes",
      })

      -- Also update on CopilotChat events
      vim.api.nvim_create_autocmd("User", {
        pattern = "CopilotChat*",
        callback = update_tmux_status,
        desc = "Update tmux status on CopilotChat events",
      })

      -- Initialize the temp file with current model
      update_tmux_status()

      -- Create a manual command to update status
      vim.api.nvim_create_user_command("CopilotUpdateStatus", function()
        update_tmux_status()
        vim.notify("Updated tmux status bar with current model", vim.log.levels.INFO)
      end, { desc = "Update tmux status bar with current CopilotChat model" })

      -- Enhanced model change detection with debugging
      local function debug_current_model()
        local copilot_chat = require("CopilotChat")
        local config_model = copilot_chat.config and copilot_chat.config.model
        local global_model = vim.g.copilot_chat_model

        -- Write debug info and update status
        vim.fn.system(
          'echo "Config: '
          .. (config_model or "nil")
          .. " | Global: "
          .. (global_model or "nil")
          .. '" > /tmp/copilot_debug'
        )

        -- Use whichever model we can find
        local current_model = config_model or global_model or "gpt-oss:20b"
        vim.fn.system('echo "' .. current_model .. '" > /tmp/copilot_current_model')

        return current_model
      end

      -- Set up a timer to periodically check and update
      local function periodic_update()
        debug_current_model()
      end

      -- Check every 3 seconds
      vim.fn.timer_start(3000, periodic_update, { ["repeat"] = -1 })
    end,

    -- Lazy-loaded keymaps
    keys = {
      { "<leader>cco", ":CopilotChat<CR>",         desc = "Open Copilot Chat" },
      { "<leader>cct", ":CopilotChatToggle<CR>",   desc = "Toggle Copilot Chat" },
      { "<leader>ccx", ":CopilotChatClose<CR>",    desc = "Close Copilot Chat" },
      { "<leader>ccr", ":CopilotChatReset<CR>",    desc = "Reset Current Chat" },
      { "<leader>ccs", ":CopilotChatSave ",        desc = "Save Chat" },
      { "<leader>ccl", ":CopilotChatLoad ",        desc = "Load Chat" },
      { "<leader>ccm", ":CopilotChatModels<CR>",   desc = "Select Chat Model" },
      { "<leader>ccu", ":CopilotUpdateStatus<CR>", desc = "Update Tmux Status" },
    },
  },
}
