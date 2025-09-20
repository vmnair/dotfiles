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

      -- Function to update tmux status with current model
      local function update_tmux_status()
        local current_model = vim.g.copilot_chat_model or "gpt-oss:20b"

        -- Update tmux variable directly using tmux command
        local cmd = string.format('tmux setenv -g copilot_model "%s" && tmux refresh-client -S', current_model)
        vim.fn.system(cmd)
      end

      -- Wrapper for vim.ui.select to detect CopilotChat model changes
      local original_ui_select = vim.ui.select
      vim.ui.select = function(items, opts, on_choice)
        -- Check if this is a CopilotChat model selection
        local is_copilot_models = opts
            and opts.prompt
            and (string.find(opts.prompt:lower(), "model") or string.find(opts.prompt:lower(), "copilot"))

        -- Create wrapped on_choice callback
        local wrapped_on_choice = on_choice
        if is_copilot_models and on_choice then
          wrapped_on_choice = function(item, idx)
            -- Store the old model for comparison
            local old_model = vim.g.copilot_chat_model

            -- Call original callback first (this updates CopilotChat internally)
            on_choice(item, idx)

            -- If a selection was made, update global variable and tmux status
            if item then
              -- Extract the new model name
              local new_model
              if type(item) == "table" and item.name then
                new_model = item.name
              elseif type(item) == "string" then
                new_model = item
              end

              -- Only update if the model actually changed
              if new_model and new_model ~= old_model then
                vim.g.copilot_chat_model = new_model

                -- Wait briefly for CopilotChat to process, then update tmux
                vim.defer_fn(function()
                  update_tmux_status()
                end, 100)
              end
            end
          end
        end

        -- Call original vim.ui.select with wrapped callback
        return original_ui_select(items, opts, wrapped_on_choice)
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

      -- Initialize tmux status with current model immediately
      update_tmux_status()

      -- Also set it with a small delay to ensure tmux is ready
      vim.defer_fn(function()
        update_tmux_status()
      end, 500)

      -- Create a manual command to update status (for troubleshooting)
      vim.api.nvim_create_user_command("CopilotUpdateStatus", function()
        update_tmux_status()
        vim.notify("Updated tmux status bar with current model", vim.log.levels.INFO)
      end, { desc = "Update tmux status bar with current CopilotChat model" })
    end,

    -- Lazy-loaded keymaps
    keys = {
      { "<leader>cco", ":CopilotChat<CR>",             desc = "Open Copilot Chat" },
      { "<leader>cct", ":CopilotChatToggle<CR>",       desc = "Toggle Copilot Chat" },
      { "<leader>ccx", ":CopilotChatClose<CR>",        desc = "Close Copilot Chat" },
      { "<leader>ccr", ":CopilotChatReset<CR>",        desc = "Reset Current Chat" },
      { "<leader>ccs", ":CopilotChatSave ",            desc = "Save Chat" },
      { "<leader>ccl", ":CopilotChatLoad ",            desc = "Load Chat" },
      { "<leader>ccm", ":CopilotChatModels<CR>",       desc = "Select Chat Model" },
      { "<leader>ccu", ":CopilotUpdateStatus<CR>",     desc = "Update Tmux Status" },
      { "<leader>cce", "<Esc>:CopilotChatExplain<CR>", desc = "Explain Code",       mode = { "n", "v" } },
    },
  },
}
