-- Lua script to get current CopilotChat model
-- This script is called from shell to extract the active AI model

local function get_current_model()
    -- Try to get CopilotChat config if loaded
    local ok, copilot_chat = pcall(require, 'CopilotChat')
    if ok and copilot_chat.config and copilot_chat.config.model then
        return copilot_chat.config.model
    end
    
    -- Fallback to checking vim global variables
    if vim.g.copilot_chat_model then
        return vim.g.copilot_chat_model
    end
    
    -- Return empty if no active model found
    return ""
end

-- Print the current model for shell capture
print(get_current_model())