local M = {}
local ollama_manager = require('vinod.ollama_manager')
local ollama_chat = require('vinod.ollama_chat')

-- Paths
local data_path = vim.fn.stdpath("data") .. "/ollama"
local chat_path = data_path .. "/chats"

-- Ensure chat directory exists
local function ensure_chat_directory()
    vim.fn.mkdir(chat_path, "p")
end

-- Generate chat filename with model and timestamp
local function generate_chat_filename(user_name, model_name)
    local timestamp = os.date("%Y%m%d-%H%M%S")
    -- Clean user_name to be filesystem safe
    local clean_name = user_name:gsub("[^%w%-_.]", "_")
    -- Clean model name (remove colons and other special chars)
    local clean_model = model_name:gsub("[^%w%-_.]", "_")
    
    return string.format("%s_%s_%s.txt", clean_name, clean_model, timestamp)
end

-- Get current chat content from active session
local function get_current_chat_content()
    local session_info = ollama_chat.get_session_info()
    
    if not session_info.active then
        return nil, "No active ollama chat session"
    end
    
    local content = {}
    
    -- Add header with metadata
    table.insert(content, "Model: " .. (session_info.model or "unknown"))
    table.insert(content, "Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(content, "---")
    table.insert(content, "")
    
    -- Get buffer content based on environment
    if vim.env.TMUX and session_info.pane_id then
        -- In tmux - capture pane content
        local cmd = string.format("tmux capture-pane -t %s -p", session_info.pane_id)
        local handle = io.popen(cmd)
        if handle then
            for line in handle:lines() do
                table.insert(content, line)
            end
            handle:close()
        else
            return nil, "Failed to capture tmux pane content"
        end
    elseif session_info.buffer_id and vim.api.nvim_buf_is_valid(session_info.buffer_id) then
        -- In neovim terminal - get buffer lines
        local lines = vim.api.nvim_buf_get_lines(session_info.buffer_id, 0, -1, false)
        for _, line in ipairs(lines) do
            table.insert(content, line)
        end
    else
        return nil, "Cannot access chat content"
    end
    
    return content, nil
end

-- Save current chat with user-provided name
function M.save_chat(user_name)
    if not user_name or user_name == "" then
        vim.ui.input({ prompt = "Enter chat name: " }, function(name)
            if name and name ~= "" then
                M.save_chat(name)
            end
        end)
        return
    end
    
    ensure_chat_directory()
    
    -- Get current session info
    local session_info = ollama_chat.get_session_info()
    if not session_info.active then
        vim.notify("No active ollama chat to save", vim.log.levels.WARN)
        return
    end
    
    -- Get chat content
    local content, err = get_current_chat_content()
    if not content then
        vim.notify("Failed to get chat content: " .. err, vim.log.levels.ERROR)
        return
    end
    
    -- Generate filename
    local filename = generate_chat_filename(user_name, session_info.model or "unknown")
    local filepath = chat_path .. "/" .. filename
    
    -- Check if file with same user_name already exists (for appending)
    local existing_files = vim.fn.glob(chat_path .. "/" .. user_name:gsub("[^%w%-_.]", "_") .. "_*.txt", false, true)
    local should_append = false
    local target_file = filepath
    
    if #existing_files > 0 then
        -- Sort to get the most recent file
        table.sort(existing_files)
        target_file = existing_files[#existing_files]
        should_append = true
    end
    
    -- Write content to file
    local file = io.open(target_file, should_append and "a" or "w")
    if not file then
        vim.notify("Failed to open file for writing: " .. target_file, vim.log.levels.ERROR)
        return
    end
    
    if should_append then
        file:write("\n\n=== Chat Session Continued ===\n")
        file:write("Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        file:write("---\n\n")
    end
    
    for _, line in ipairs(content) do
        file:write(line .. "\n")
    end
    
    file:close()
    
    local action = should_append and "appended to" or "saved as"
    vim.notify("Chat " .. action .. ": " .. vim.fn.fnamemodify(target_file, ":t"), vim.log.levels.INFO)
end

-- Get list of saved chats
function M.get_saved_chats()
    ensure_chat_directory()
    
    local chat_files = vim.fn.glob(chat_path .. "/*.txt", false, true)
    local chats = {}
    
    for _, filepath in ipairs(chat_files) do
        local filename = vim.fn.fnamemodify(filepath, ":t")
        local stat = vim.loop.fs_stat(filepath)
        
        table.insert(chats, {
            name = filename,
            path = filepath,
            modified = stat and stat.mtime.sec or 0,
        })
    end
    
    -- Sort by modification time (newest first)
    table.sort(chats, function(a, b) return a.modified > b.modified end)
    
    return chats
end

-- Load saved chat in new buffer
function M.load_chat()
    local saved_chats = M.get_saved_chats()
    
    if #saved_chats == 0 then
        vim.notify("No saved chats found", vim.log.levels.INFO)
        return
    end
    
    -- Create list for selection
    local chat_names = {}
    for _, chat in ipairs(saved_chats) do
        local display_name = chat.name
        -- Add modification date for context
        local date_str = os.date("%Y-%m-%d %H:%M", chat.modified)
        display_name = display_name .. " (" .. date_str .. ")"
        table.insert(chat_names, display_name)
    end
    
    -- Use vim.ui.select for chat selection
    vim.ui.select(chat_names, {
        prompt = "Select chat to load: ",
        format_item = function(item)
            return item
        end,
    }, function(choice, idx)
        if choice and idx then
            local selected_chat = saved_chats[idx]
            M.open_chat_file(selected_chat.path)
        end
    end)
end

-- Open chat file in new buffer
function M.open_chat_file(filepath)
    if not vim.fn.filereadable(filepath) then
        vim.notify("Chat file not found: " .. filepath, vim.log.levels.ERROR)
        return
    end
    
    -- Create new buffer
    local buf = vim.api.nvim_create_buf(false, false)
    
    -- Read file content
    local lines = {}
    for line in io.lines(filepath) do
        table.insert(lines, line)
    end
    
    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Set buffer properties
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nowrite')
    vim.api.nvim_buf_set_option(buf, 'readonly', true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Set buffer name
    local filename = vim.fn.fnamemodify(filepath, ":t")
    vim.api.nvim_buf_set_name(buf, "Ollama Chat: " .. filename)
    
    -- Open in new split
    local split_pref = ollama_manager.get_split_preference()
    local split_cmd = split_pref == "vertical" and "vsplit" or "split"
    vim.cmd(split_cmd)
    vim.api.nvim_win_set_buf(0, buf)
    
    vim.notify("Loaded chat: " .. filename, vim.log.levels.INFO)
end

-- Clear all saved chats with confirmation
function M.clear_all_chats()
    local saved_chats = M.get_saved_chats()
    
    if #saved_chats == 0 then
        vim.notify("No saved chats to clear", vim.log.levels.INFO)
        return
    end
    
    local count = #saved_chats
    local confirm_msg = string.format("Delete all %d saved chats? This cannot be undone.", count)
    
    vim.ui.select({"Yes", "No"}, {
        prompt = confirm_msg,
    }, function(choice)
        if choice == "Yes" then
            local deleted_count = 0
            for _, chat in ipairs(saved_chats) do
                if vim.fn.delete(chat.path) == 0 then
                    deleted_count = deleted_count + 1
                end
            end
            vim.notify("Deleted " .. deleted_count .. " chat files", vim.log.levels.INFO)
        end
    end)
end

-- Show saved chats info
function M.show_chat_info()
    local saved_chats = M.get_saved_chats()
    
    local info_lines = {
        "=== Saved Ollama Chats ===",
        "",
        "Total saved chats: " .. #saved_chats,
        "Storage location: " .. chat_path,
        "",
    }
    
    if #saved_chats > 0 then
        table.insert(info_lines, "Recent chats:")
        for i, chat in ipairs(saved_chats) do
            if i > 10 then break end -- Show only top 10
            local date_str = os.date("%Y-%m-%d %H:%M", chat.modified)
            table.insert(info_lines, string.format("  %d. %s (%s)", i, chat.name, date_str))
        end
        
        if #saved_chats > 10 then
            table.insert(info_lines, string.format("  ... and %d more", #saved_chats - 10))
        end
    else
        table.insert(info_lines, "No saved chats found.")
        table.insert(info_lines, "Use <leader>os to save current chat.")
    end
    
    -- Show in new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, info_lines)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'readonly', true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Open in split
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_name(buf, "Ollama Chat Info")
end

return M