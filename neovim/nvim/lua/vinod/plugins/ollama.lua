-- ollama.lua - Async Ollama API integration using plenary.job
-- Plugin spec for lazy.nvim

return {
  "nvim-lua/plenary.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  config = function()
    local Job = require("plenary.job")

    -- Progress tracking state
    local progress_lines = {}
    local total_models = 0
    local completed_models = 0

    -- Async function to make HTTP requests to Ollama API
    -- @param endpoint string The API endpoint (e.g., "/api/tags")
    -- @param data table|nil Optional data table for POST requests (will be JSON encoded)
    -- @param callback function Callback with (success: boolean, response: table|string)
    local function api_request_async(endpoint, data, callback)
      local url = "http://127.0.0.1:11434" .. endpoint
      local args = {
        "-s",
        "--max-time", "120", -- 2 minute timeout for large models
        url
      }

      -- Add POST data if provided
      if data then
        table.insert(args, "-X")
        table.insert(args, "POST")
        table.insert(args, "-H")
        table.insert(args, "Content-Type: application/json")
        table.insert(args, "-d")
        table.insert(args, vim.json.encode(data))
      end

      Job:new({
        command = "curl",
        args = args,
        on_exit = function(j, return_val)
          -- Schedule callback to run in main thread
          vim.schedule(function()
            if return_val == 0 then
              local result = table.concat(j:result(), "\n")
              if result == "" then
                callback(false, "Empty response from API")
                return
              end

              local ok, decoded = pcall(vim.json.decode, result)
              if ok then
                callback(true, decoded)
              else
                callback(false, "JSON parse error: " .. result)
              end
            elseif return_val == 28 then
              -- curl exit code 28 = timeout
              callback(false, "Request timed out after 2 minutes")
            else
              local error_output = table.concat(j:stderr_result(), "\n")
              callback(false, "Request failed (exit " .. return_val .. "): " .. error_output)
            end
          end)
        end,
      }):start()
    end

    -- Async function to get a list of local Ollama models
    -- @param callback function Callback with (models: table) - list of model objects
    local function get_local_models_async(callback)
      api_request_async("/api/tags", nil, function(success, response)
        if success and response.models then
          callback(response.models)
        else
          print("Failed to get models: " .. (type(response) == "string" and response or "Unknown error"))
          callback({})
        end
      end)
    end

    -- Async function to update a single model
    -- @param index number The model index (for display)
    -- @param model_name string The name of the model to update
    -- @param on_complete function Optional callback when update completes
    local function update_model_async(index, model_name, on_complete)
      api_request_async("/api/pull", {
        name = model_name,
        stream = false,
      }, function(success, response)
        completed_models = completed_models + 1

        -- Store result (only for final summary)
        if success then
          if response.status == "success" then
            table.insert(progress_lines, "✓ " .. model_name)
          elseif response.status then
            table.insert(progress_lines, "ℹ " .. model_name .. " - " .. response.status)
          else
            table.insert(progress_lines, "✓ " .. model_name)
          end
        else
          table.insert(progress_lines, "✗ " .. model_name)
        end

        if on_complete then
          on_complete()
        end
      end)
    end

    -- Phase 1: Check for updates (presents list, doesn't download)
    vim.api.nvim_create_user_command("OllamaCheck", function()
      print("⏳ Fetching local model list...")

      get_local_models_async(function(models)
        if #models == 0 then
          require("snacks").notify("⚠ No models found", {
            title = "Ollama Check",
            level = vim.log.levels.WARN,
            timeout = 3000,
          })
          return
        end

        print("\n📦 Found " .. #models .. " local models:\n")
        for i, model in ipairs(models) do
          local size_gb = math.floor(model.size / 1024 / 1024 / 1024 * 10) / 10
          local is_large = size_gb > 50
          print(string.format(
            "  %d. %s (%.1f GB)%s",
            i,
            model.name,
            size_gb,
            is_large and " ⚠️  LARGE" or ""
          ))
        end

        print("\n💡 Use :OllamaUpdateAllModels to update all models")
        print("💡 Use :OllamaUpdateModel <model-name> to update specific model\n")
      end)
    end, { desc = "Check local Ollama models without downloading" })

    -- Phase 2: Update specific model (no confirmation needed)
    vim.api.nvim_create_user_command("OllamaUpdateModel", function(opts)
      local model_name = opts.args

      if model_name == "" then
        print("❌ Usage: :OllamaUpdateModel <model-name>")
        return
      end

      -- Reset state
      progress_lines = {}
      total_models = 1
      completed_models = 0

      require("snacks").notify("Updating " .. model_name .. "...", {
        title = "Ollama Update",
        level = vim.log.levels.INFO,
      })

      update_model_async(1, model_name, function()
        require("snacks").notify("✓ " .. model_name .. " updated", {
          title = "Ollama Update",
          level = vim.log.levels.INFO,
          timeout = 3000,
        })
      end)
    end, {
      desc = "Update a specific Ollama model",
      nargs = 1,
      complete = function()
        -- Provide model name completion
        local models = {}
        get_local_models_async(function(model_list)
          for _, model in ipairs(model_list) do
            table.insert(models, model.name)
          end
        end)
        return models
      end
    })

    -- Phase 3: Update all models with async confirmation
    vim.api.nvim_create_user_command("OllamaUpdateAllModels", function()
      get_local_models_async(function(models)
        if #models == 0 then
          require("snacks").notify("No models found", {
            title = "Ollama Update",
            level = vim.log.levels.WARN,
          })
          return
        end

        -- Show what will be updated
        local model_list = {}
        for i, model in ipairs(models) do
          local size_gb = math.floor(model.size / 1024 / 1024 / 1024 * 10) / 10
          table.insert(model_list, string.format("  • %s (%.1f GB)", model.name, size_gb))
        end

        local prompt_msg = string.format(
          "About to check updates for %d models:\n%s\n\nLarge models may download if updates exist.\n\nContinue?",
          #models,
          table.concat(model_list, "\n")
        )

        -- Use async input (non-blocking)
        vim.ui.input({
          prompt = prompt_msg .. " (y/n): ",
          default = "y",
        }, function(input)
          -- This callback runs asynchronously
          if not input or input:lower() ~= "y" then
            require("snacks").notify("Update cancelled", {
              title = "Ollama Update",
              level = vim.log.levels.INFO,
              timeout = 2000,
            })
            return
          end

          -- User confirmed, proceed with updates
          progress_lines = {}
          total_models = #models
          completed_models = 0
          local start_time = vim.loop.hrtime()

          -- Show initial notification
          require("snacks").notify(string.format("Checking %d models...", #models), {
            title = "Ollama Update",
            level = vim.log.levels.INFO,
            timeout = 2000,
          })

          for index, model in ipairs(models) do
            update_model_async(index, model.name, function()
              if completed_models == total_models then
                local elapsed_ms = (vim.loop.hrtime() - start_time) / 1000000
                local elapsed_sec = elapsed_ms / 1000

                local summary_msg = string.format(
                  "Checked %d models in %.2f seconds\n\n%s",
                  total_models,
                  elapsed_sec,
                  table.concat(progress_lines, "\n")
                )

                require("snacks").notify(summary_msg, {
                  title = "Ollama Update Complete",
                  level = vim.log.levels.INFO,
                  timeout = 5000,
                })
              end
            end)
          end
        end)
      end)
    end, { desc = "Update all Ollama models with confirmation" })
  end,
}
