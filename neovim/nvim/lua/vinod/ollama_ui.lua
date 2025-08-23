local M = {}
local ollama_manager = require('vinod.ollama_manager')

-- Check if fzf-lua is available
local function has_fzf_lua()
    return pcall(require, 'fzf-lua')
end

-- Create temporary script for tmux popup fzf
local function create_tmux_fzf_script(models, prompt_text)
    local temp_script = vim.fn.tempname() .. "_ollama_select.sh"
    local models_str = table.concat(models, "\n")
    
    local script_content = string.format([[#!/bin/bash
echo '%s' | fzf --prompt="%s" --height=40%% --layout=reverse --border
]], models_str, prompt_text)
    
    -- Write script to temp file
    local file = io.open(temp_script, "w")
    if file then
        file:write(script_content)
        file:close()
        -- Make executable
        os.execute("chmod +x " .. temp_script)
        return temp_script
    end
    
    return nil
end

-- Show model selection using tmux popup
local function select_model_tmux(models, prompt_text, callback)
    if #models == 0 then
        vim.notify("No models available", vim.log.levels.ERROR)
        callback(nil)
        return
    end
    
    -- Check if tmux is actually available
    if os.execute("which tmux >/dev/null 2>&1") ~= 0 then
        vim.notify("Tmux not found, falling back to alternative selection", vim.log.levels.WARN)
        select_model_fallback(models, prompt_text, callback)
        return
    end
    
    -- Create temporary fzf script
    local script_path = create_tmux_fzf_script(models, prompt_text)
    if not script_path then
        vim.notify("Failed to create selection script", vim.log.levels.ERROR)
        callback(nil)
        return
    end
    
    -- Run tmux popup with the script and capture output
    local result_file = vim.fn.tempname()
    local popup_cmd = string.format(
        "tmux display-popup -E -w 60 -h 15 'bash %s > %s 2>/dev/null'",
        script_path, result_file
    )
    
    vim.fn.jobstart(popup_cmd, {
        on_exit = function(_, exit_code)
            -- Read result from temp file
            local selected = nil
            if vim.fn.filereadable(result_file) == 1 then
                local lines = vim.fn.readfile(result_file)
                if #lines > 0 then
                    selected = lines[1]:match("^%s*(.-)%s*$") -- Trim whitespace
                    if selected == "" then selected = nil end
                end
            end
            
            -- Clean up temp files
            os.remove(script_path)
            os.remove(result_file)
            
            callback(selected)
        end,
    })
end

-- Show model selection using fzf-lua
local function select_model_fzf_lua(models, prompt_text, callback)
    if not has_fzf_lua() then
        vim.notify("fzf-lua not available", vim.log.levels.ERROR)
        callback(nil)
        return
    end
    
    local fzf = require('fzf-lua')
    
    fzf.fzf_exec(models, {
        prompt = prompt_text,
        winopts = {
            height = 0.4,
            width = 0.6,
            border = "rounded",
        },
        actions = {
            ['default'] = function(selected)
                if selected and #selected > 0 then
                    callback(selected[1])
                else
                    callback(nil)
                end
            end,
        },
    })
end

-- Fallback model selection using vim.ui.select
local function select_model_fallback(models, prompt_text, callback)
    vim.ui.select(models, {
        prompt = prompt_text,
        format_item = function(item)
            return item
        end,
    }, function(choice)
        callback(choice)
    end)
end

-- Main model selection function (context-aware)
function M.select_model(prompt_text, callback)
    -- Get available models
    local models, err = ollama_manager.get_available_models()
    if not models then
        vim.notify("Error getting models: " .. (err or "unknown error"), vim.log.levels.ERROR)
        callback(nil)
        return
    end
    
    if #models == 0 then
        vim.notify("No ollama models found. Install models with: ollama pull <model_name>", vim.log.levels.WARN)
        callback(nil)
        return
    end
    
    prompt_text = prompt_text or "Select Ollama model: "
    
    -- Check environment and use appropriate selection method
    if vim.env.TMUX then
        -- In tmux - use popup
        select_model_tmux(models, prompt_text, callback)
    elseif has_fzf_lua() then
        -- Outside tmux with fzf-lua - use fzf-lua
        select_model_fzf_lua(models, prompt_text, callback)  
    else
        -- Fallback to vim.ui.select
        select_model_fallback(models, prompt_text, callback)
    end
end

-- Select default model with automatic config saving
function M.select_default_model()
    M.select_model("Select default Ollama model: ", function(selected_model)
        if selected_model then
            ollama_manager.set_default_model(selected_model)
        end
    end)
end

-- Select model for current session (doesn't save as default)
function M.select_session_model(callback)
    M.select_model("Select Ollama model for this session: ", callback)
end

-- Show model information
function M.show_model_info()
    local models, err = ollama_manager.get_available_models()
    if not models then
        vim.notify("Error getting models: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
    end
    
    local default_model = ollama_manager.get_default_model()
    local current_session = ollama_manager.get_session_info()
    
    local info_lines = {
        "=== Ollama Model Information ===",
        "",
        "Available models: " .. #models,
    }
    
    for i, model in ipairs(models) do
        local marker = ""
        if model == default_model then
            marker = marker .. " [DEFAULT]"
        end
        if current_session.model == model then
            marker = marker .. " [ACTIVE]"
        end
        table.insert(info_lines, "  " .. i .. ". " .. model .. marker)
    end
    
    table.insert(info_lines, "")
    table.insert(info_lines, "Default model: " .. (default_model or "none set"))
    table.insert(info_lines, "Active session model: " .. (current_session.model or "none"))
    table.insert(info_lines, "Split preference: " .. ollama_manager.get_split_preference())
    
    -- Show in a new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, info_lines)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'readonly', true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Open in a split
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_name(buf, "Ollama Model Info")
end

return M