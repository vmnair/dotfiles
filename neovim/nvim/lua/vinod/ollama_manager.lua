local M = {}

-- Module state for tracking ollama sessions
local ollama_session = {
    pane_id = nil,          -- tmux pane ID or Neovim buffer number  
    model = nil,            -- current model being used
    process_id = nil,       -- ollama process ID
    is_visible = false,     -- current visibility state
    buffer_id = nil,        -- neovim buffer id for chat
}

-- Paths for configuration and data storage
local config_path = vim.fn.stdpath("config") .. "/ollama_config.lua"
local data_path = vim.fn.stdpath("data") .. "/ollama"
local chat_path = data_path .. "/chats"

-- Utility function to check if we're in tmux
local function is_in_tmux()
    return vim.env.TMUX ~= nil
end

-- Utility function to execute shell command and get output
local function execute_command(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute command"
    end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("\n$", ""), nil -- Remove trailing newline
end

-- Force tmux status bar refresh
local function refresh_tmux_status()
    if is_in_tmux() then
        os.execute("tmux refresh-client -S")
    end
end

-- Create necessary directories
local function ensure_directories()
    -- Create data directory
    vim.fn.mkdir(data_path, "p")
    -- Create chats directory  
    vim.fn.mkdir(chat_path, "p")
end

-- Load configuration from Lua file
function M.load_config()
    -- Ensure config file exists
    if vim.fn.filereadable(config_path) == 0 then
        return nil -- No config file
    end
    
    -- Load the config file
    local ok, config = pcall(dofile, config_path)
    if not ok then
        vim.notify("Error loading ollama config: " .. config, vim.log.levels.ERROR)
        return nil
    end
    
    return config
end

-- Save configuration to Lua file
function M.save_config(config)
    ensure_directories()
    
    -- Create config content
    local content = string.format([[-- Ollama configuration
-- Generated automatically, safe to edit manually

return {
    default_model = "%s",
    split_preference = "%s",
    last_updated = "%s"
}
]], config.default_model or "", config.split_preference or "horizontal", os.date("%Y-%m-%d"))
    
    -- Write config file
    local file = io.open(config_path, "w")
    if file then
        file:write(content)
        file:close()
        -- Refresh tmux status bar to show updated model
        refresh_tmux_status()
        return true
    else
        vim.notify("Failed to save ollama config", vim.log.levels.ERROR)
        return false
    end
end

-- Get list of available ollama models
function M.get_available_models()
    -- Check if ollama is available
    local check_cmd = "which ollama >/dev/null 2>&1"
    if os.execute(check_cmd) ~= 0 then
        return nil, "Ollama is not installed or not in PATH"
    end
    
    -- Get model list
    local output, err = execute_command("ollama list")
    if not output then
        return nil, err or "Failed to get model list"
    end
    
    -- Check if ollama service is running
    if output:match("connect: connection refused") or output:match("Is the ollama server running") then
        return nil, "Ollama server is not running. Please start it with: ollama serve"
    end
    
    -- Parse model list (skip header line)
    local models = {}
    local lines = vim.split(output, "\n")
    
    for i = 2, #lines do -- Skip header line
        local line = lines[i]:match("^%s*(.-)%s*$") -- Trim whitespace
        if line and line ~= "" then
            -- Extract model name (first column)
            local model_name = line:match("^(%S+)")
            if model_name and model_name ~= "" then
                table.insert(models, model_name)
            end
        end
    end
    
    if #models == 0 then
        return nil, "No models found. Please install models with: ollama pull <model_name>"
    end
    
    return models, nil
end

-- Validate that a specific model exists
function M.validate_model(model_name)
    if not model_name or model_name == "" then
        return false, "Model name cannot be empty"
    end
    
    local models, err = M.get_available_models()
    if not models then
        return false, err
    end
    
    for _, model in ipairs(models) do
        if model == model_name then
            return true, nil
        end
    end
    
    return false, "Model '" .. model_name .. "' not found. Available models: " .. table.concat(models, ", ")
end

-- Get default model from config
function M.get_default_model()
    local config = M.load_config()
    if config and config.default_model then
        -- Validate the default model is still available
        local is_valid, err = M.validate_model(config.default_model)
        if is_valid then
            return config.default_model
        else
            vim.notify("Default model '" .. config.default_model .. "' is no longer available: " .. err, vim.log.levels.WARN)
            return nil
        end
    end
    return nil
end

-- Set default model in config
function M.set_default_model(model_name)
    -- Validate model first
    local is_valid, err = M.validate_model(model_name)
    if not is_valid then
        vim.notify("Cannot set default model: " .. err, vim.log.levels.ERROR)
        return false
    end
    
    -- Load existing config or create new one
    local config = M.load_config() or {}
    config.default_model = model_name
    
    -- Save config
    if M.save_config(config) then
        vim.notify("Default model set to: " .. model_name, vim.log.levels.INFO)
        return true
    else
        return false
    end
end

-- Get split preference from config
function M.get_split_preference()
    local config = M.load_config()
    if config and config.split_preference then
        return config.split_preference
    end
    return "horizontal" -- Default
end

-- Set split preference in config
function M.set_split_preference(preference)
    if preference ~= "horizontal" and preference ~= "vertical" then
        vim.notify("Split preference must be 'horizontal' or 'vertical'", vim.log.levels.ERROR)
        return false
    end
    
    -- Load existing config or create new one
    local config = M.load_config() or {}
    config.split_preference = preference
    
    -- Save config
    if M.save_config(config) then
        vim.notify("Split preference set to: " .. preference, vim.log.levels.INFO)
        return true
    else
        return false
    end
end

-- Check if there's an active ollama session
function M.has_active_session()
    return ollama_session.pane_id ~= nil
end

-- Get current session info
function M.get_session_info()
    return {
        pane_id = ollama_session.pane_id,
        model = ollama_session.model,
        process_id = ollama_session.process_id,
        is_visible = ollama_session.is_visible,
        buffer_id = ollama_session.buffer_id,
    }
end

-- Clean up old chat files (older than 30 days)
function M.cleanup_old_chats()
    ensure_directories()
    
    local cutoff_time = os.time() - (30 * 24 * 60 * 60) -- 30 days ago
    local cleaned_count = 0
    
    -- Get list of chat files
    local chat_files = vim.fn.glob(chat_path .. "/*.txt", false, true)
    
    for _, file_path in ipairs(chat_files) do
        local stat = vim.loop.fs_stat(file_path)
        if stat and stat.mtime.sec < cutoff_time then
            if vim.fn.delete(file_path) == 0 then
                cleaned_count = cleaned_count + 1
            end
        end
    end
    
    if cleaned_count > 0 then
        vim.notify("Cleaned up " .. cleaned_count .. " old chat files", vim.log.levels.INFO)
    end
end

-- Initialize the ollama manager
function M.setup()
    ensure_directories()
    M.cleanup_old_chats()
end

return M