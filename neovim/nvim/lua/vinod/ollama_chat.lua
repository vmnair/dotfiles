local M = {}
local ollama_manager = require("vinod.ollama_manager")
local ollama_ui = require("vinod.ollama_ui")

-- Module state for tracking ollama sessions
local ollama_session = {
  pane_id = nil,      -- tmux pane ID or Neovim buffer number
  model = nil,        -- current model being used
  process_id = nil,   -- ollama process ID
  is_visible = false, -- current visibility state
  buffer_id = nil,    -- neovim buffer id for chat
  job_id = nil,       -- neovim job id
}

-- Check if we're in tmux
local function is_in_tmux()
  return vim.env.TMUX ~= nil
end

-- Check if a tmux pane exists
local function tmux_pane_exists(pane_id)
  if not pane_id then
    return false
  end
  local cmd = "tmux list-panes -F '#{pane_id}' | grep -q '" .. pane_id .. "'"
  return os.execute(cmd) == 0
end

-- Get current tmux pane ID
local function get_current_tmux_pane()
  local handle = io.popen("tmux display-message -p '#{pane_id}'")
  if not handle then
    return nil
  end
  local pane_id = handle:read("*l")
  handle:close()
  return pane_id
end

-- Create tmux split and start ollama
local function start_ollama_tmux(model_name)
  local split_pref = ollama_manager.get_split_preference()
  local split_cmd = split_pref == "vertical" and "split-window -h" or "split-window"

  -- Create split
  local create_split = string.format("tmux %s -p 50", split_cmd)
  os.execute(create_split)

  -- Get the new pane ID
  local new_pane_id = get_current_tmux_pane()
  if not new_pane_id then
    vim.notify("Failed to get tmux pane ID", vim.log.levels.ERROR)
    return false
  end

  -- Start ollama in the new pane
  local ollama_cmd = string.format("tmux send-keys -t %s 'ollama run %s' C-m", new_pane_id, model_name)
  os.execute(ollama_cmd)

  -- Update session state
  ollama_session.pane_id = new_pane_id
  ollama_session.model = model_name
  ollama_session.is_visible = true

  return true
end

-- Create neovim terminal and start ollama
local function start_ollama_terminal(model_name)
  local split_pref = ollama_manager.get_split_preference()
  local split_cmd = split_pref == "vertical" and "vsplit" or "split"

  -- Create terminal buffer
  vim.cmd(split_cmd)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_win_set_buf(0, buf)

  -- Start ollama in terminal
  local job_id = vim.fn.termopen("ollama run " .. model_name, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Ollama process exited with code " .. exit_code, vim.log.levels.WARN)
      end
      -- Clear session state when process exits
      ollama_session.job_id = nil
      ollama_session.buffer_id = nil
      ollama_session.process_id = nil
    end,
  })

  if job_id <= 0 then
    vim.notify("Failed to start ollama terminal", vim.log.levels.ERROR)
    return false
  end

  -- Update session state
  ollama_session.buffer_id = buf
  ollama_session.job_id = job_id
  ollama_session.model = model_name
  ollama_session.is_visible = true

  return true
end

-- Start ollama chat with specified model
local function start_ollama_with_model(model_name)
  -- Validate model first
  local is_valid, err = ollama_manager.validate_model(model_name)
  if not is_valid then
    vim.notify("Cannot start chat: " .. err, vim.log.levels.ERROR)
    return false
  end

  vim.notify("Starting ollama with model: " .. model_name, vim.log.levels.INFO)
  vim.notify("Loading model... (this may take a moment)", vim.log.levels.INFO)

  -- Start ollama based on environment
  if is_in_tmux() then
    return start_ollama_tmux(model_name)
  else
    return start_ollama_terminal(model_name)
  end
end

-- Kill current ollama process
local function kill_current_ollama()
  if ollama_session.job_id then
    -- Neovim terminal - send exit command then kill job
    vim.fn.chansend(ollama_session.job_id, "/bye\n")
    vim.defer_fn(function()
      if ollama_session.job_id then
        vim.fn.jobstop(ollama_session.job_id)
      end
    end, 1000)
  elseif ollama_session.pane_id and is_in_tmux() then
    -- Tmux - send exit command to pane
    local exit_cmd = string.format("tmux send-keys -t %s '/bye' C-m", ollama_session.pane_id)
    os.execute(exit_cmd)
  end
end

-- Hide ollama chat pane
local function hide_ollama_pane()
  if is_in_tmux() and ollama_session.pane_id then
    -- In tmux, just switch to other pane (keep process running)
    os.execute("tmux last-pane")
    ollama_session.is_visible = false
  elseif ollama_session.buffer_id then
    -- In neovim, close the window but keep buffer
    local wins = vim.api.nvim_list_wins()
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_get_buf(win) == ollama_session.buffer_id then
        vim.api.nvim_win_close(win, false)
        ollama_session.is_visible = false
        break
      end
    end
  end
end

-- Show ollama chat pane
local function show_ollama_pane()
  if is_in_tmux() and ollama_session.pane_id then
    -- In tmux, select the ollama pane
    local select_cmd = string.format("tmux select-pane -t %s", ollama_session.pane_id)
    os.execute(select_cmd)
    ollama_session.is_visible = true
  elseif ollama_session.buffer_id and vim.api.nvim_buf_is_valid(ollama_session.buffer_id) then
    -- In neovim, open the buffer in a split
    local split_pref = ollama_manager.get_split_preference()
    local split_cmd = split_pref == "vertical" and "vsplit" or "split"
    vim.cmd(split_cmd)
    vim.api.nvim_win_set_buf(0, ollama_session.buffer_id)
    ollama_session.is_visible = true
  end
end

-- Check if session is valid
local function is_session_valid()
  if is_in_tmux() then
    return ollama_session.pane_id and tmux_pane_exists(ollama_session.pane_id)
  else
    return ollama_session.buffer_id and vim.api.nvim_buf_is_valid(ollama_session.buffer_id)
  end
end

-- Open ollama chat with default model
function M.open_chat()
  -- Check if there's already an active session
  if is_session_valid() then
    if not ollama_session.is_visible then
      show_ollama_pane()
    else
      vim.notify("Ollama chat is already active", vim.log.levels.INFO)
    end
    return
  end

  -- Get default model
  local default_model = ollama_manager.get_default_model()

  if not default_model then
    -- No default model - prompt user to select one
    vim.notify("No default model set. Please select one:", vim.log.levels.INFO)
    ollama_ui.select_model("Select default Ollama model: ", function(selected_model)
      if selected_model then
        ollama_manager.set_default_model(selected_model)
        start_ollama_with_model(selected_model)
      end
    end)
  else
    -- Use default model
    start_ollama_with_model(default_model)
  end
end

-- Set default model
function M.set_default_model()
  ollama_ui.select_default_model()
end

-- Switch model in current session
function M.switch_model()
  ollama_ui.select_session_model(function(selected_model)
    if selected_model then
      vim.notify("Switching to model: " .. selected_model, vim.log.levels.INFO)

      -- Update the persistent configuration with new model
      local config = ollama_manager.load_config() or {}
      config.default_model = selected_model
      ollama_manager.save_config(config)

      -- Kill current ollama process
      if is_session_valid() then
        kill_current_ollama()
        -- Wait a moment then start new model
        vim.defer_fn(function()
          start_ollama_with_model(selected_model)
        end, 1500)
      else
        -- No active session, just start with new model
        start_ollama_with_model(selected_model)
      end
    end
  end)
end

-- Toggle chat visibility
function M.toggle_chat()
  if not is_session_valid() then
    -- No valid session - start new chat
    M.open_chat()
    return
  end

  if ollama_session.is_visible then
    hide_ollama_pane()
  else
    show_ollama_pane()
  end
end

-- Close chat session
function M.close_chat()
  if not is_session_valid() then
    vim.notify("No active ollama chat to close", vim.log.levels.INFO)
    return
  end

  -- Kill the ollama process
  kill_current_ollama()

  -- Close the pane/buffer
  if is_in_tmux() and ollama_session.pane_id then
    local kill_cmd = string.format("tmux kill-pane -t %s", ollama_session.pane_id)
    os.execute(kill_cmd)
  elseif ollama_session.buffer_id then
    vim.api.nvim_buf_delete(ollama_session.buffer_id, { force = true })
  end

  -- Clear session state
  ollama_session = {
    pane_id = nil,
    model = nil,
    process_id = nil,
    is_visible = false,
    buffer_id = nil,
    job_id = nil,
  }

  vim.notify("Ollama chat closed", vim.log.levels.INFO)
end

-- Set split preference
function M.set_horizontal_split()
  ollama_manager.set_split_preference("horizontal")
end

function M.set_vertical_split()
  ollama_manager.set_split_preference("vertical")
end


-- Get the current active model (from session if available, otherwise from config)
local function get_current_model()
  if ollama_session.model then
    return ollama_session.model
  end
  
  local config = ollama_manager.load_config()
  if config and config.default_model then
    return config.default_model
  end
  
  -- Last fallback - should not happen if config is set up properly
  vim.notify("No model configured. Please set default model with :OllamaSetDefault", vim.log.levels.WARN)
  return nil
end

-- Send current buffer content to Ollama via API (no terminal session needed)
function M.send_buffer_context()
  -- Get current buffer content directly without session check

  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  if vim.trim(content) == '' then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  -- Get filename for context
  local filename = vim.api.nvim_buf_get_name(0)
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"

  -- Create system message for proper context loading
  local system_message = string.format([[You are a coding assistant. A file named '%s' has been loaded into your context. Please acknowledge by responding with exactly: "Context loaded: %s (%d lines)"

Do not analyze, explain, or discuss the code. Just acknowledge the context loading with the requested response format.]], display_name, display_name, #lines)

  -- Get the current active model
  local current_model = get_current_model()
  if not current_model then
    vim.notify("Cannot send buffer context: no model available", vim.log.levels.ERROR)
    return
  end

  -- Create API request payload
  local payload = {
    model = current_model,
    messages = {
      {
        role = "system",
        content = system_message
      },
      {
        role = "user", 
        content = content
      }
    },
    stream = true
  }

  local curl = require('plenary.curl')

  vim.notify("Loading context into " .. current_model .. "...", vim.log.levels.INFO)

  -- Make streaming API request
  curl.post('http://localhost:11434/api/chat', {
    headers = {
      ['Content-Type'] = 'application/json',
    },
    body = vim.fn.json_encode(payload),
    stream = false,
    callback = function(out)
      vim.schedule(function()
        if out.status == 200 and out.body then
          -- Process the complete response body to get context confirmation
          local response_lines = {}
          
          -- Parse each JSON line from the response body
          for line in out.body:gmatch("[^\n]+") do
            local success, response = pcall(vim.fn.json_decode, line)
            if success and response.message and response.message.content then
              table.insert(response_lines, response.message.content)
            end
          end
          
          if #response_lines > 0 then
            local context_confirmation = table.concat(response_lines, "")
            -- Open interactive API chat with context confirmation
            M.open_api_chat(context_confirmation)
          else
            vim.notify("No valid response received from API", vim.log.levels.WARN)
          end
        else
          vim.notify("API Error: " .. out.status .. " - " .. (out.body or "Unknown error"), vim.log.levels.ERROR)
        end
      end)
    end,
    on_error = function(err)
      vim.schedule(function()
        vim.notify("Request failed: " .. vim.inspect(err), vim.log.levels.ERROR)
      end)
    end
  })
end

-- Send visual selection to Ollama via API
function M.send_visual_selection()
  -- Get visual selection - need to exit visual mode first to get proper marks
  vim.cmd('normal! <Esc>') -- Exit visual mode to set marks properly

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    vim.notify("No visual selection found", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  -- Handle partial line selection
  if #lines > 0 then
    if #lines == 1 then
      -- Single line selection
      lines[1] = lines[1]:sub(start_pos[3], end_pos[3])
    else
      -- Multi-line selection
      lines[1] = lines[1]:sub(start_pos[3])
      lines[#lines] = lines[#lines]:sub(1, end_pos[3])
    end
  end

  local content = table.concat(lines, "\n")

  if content == "" then
    vim.notify("Selected content is empty", vim.log.levels.WARN)
    return
  end

  local filename = vim.api.nvim_buf_get_name(0)
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"

  -- Create system message for proper context loading
  local system_message = string.format([[You are a coding assistant. A code selection from '%s' has been loaded into your context. Please acknowledge by responding with exactly: "Selection loaded: %s (%d lines)"

Do not analyze, explain, or discuss the code. Just acknowledge the selection loading with the requested response format.]], display_name, display_name, #lines)

  -- Get the current active model
  local current_model = get_current_model()
  if not current_model then
    vim.notify("Cannot send buffer context: no model available", vim.log.levels.ERROR)
    return
  end

  -- Create API request payload
  local payload = {
    model = current_model,
    messages = {
      {
        role = "system",
        content = system_message
      },
      {
        role = "user", 
        content = content
      }
    },
    stream = true
  }

  -- Get current model for API request
  local current_model = get_current_model()
  if not current_model then
    vim.notify("Cannot send selection context: no model available", vim.log.levels.ERROR)
    return
  end

  local curl = require('plenary.curl')

  vim.notify("Loading selection context into " .. current_model .. "...", vim.log.levels.INFO)

  -- Make API request
  curl.post('http://localhost:11434/api/chat', {
    headers = {
      ['Content-Type'] = 'application/json',
    },
    body = vim.fn.json_encode(payload),
    stream = false,
    callback = function(out)
      vim.schedule(function()
        if out.status == 200 and out.body then
          -- Process the complete response body to get context confirmation
          local response_lines = {}
          
          -- Parse each JSON line from the response body
          for line in out.body:gmatch("[^\n]+") do
            local success, response = pcall(vim.fn.json_decode, line)
            if success and response.message and response.message.content then
              table.insert(response_lines, response.message.content)
            end
          end
          
          if #response_lines > 0 then
            local context_confirmation = table.concat(response_lines, "")
            -- Open interactive API chat with context confirmation
            M.open_api_chat(context_confirmation)
          else
            vim.notify("No valid response received from API", vim.log.levels.WARN)
          end
        else
          vim.notify("API Error: " .. out.status .. " - " .. (out.body or "Unknown error"), vim.log.levels.ERROR)
        end
      end)
    end,
    on_error = function(err)
      vim.schedule(function()
        vim.notify("Request failed: " .. vim.inspect(err), vim.log.levels.ERROR)
      end)
    end
  })
end

-- Get session information
function M.get_session_info()
  return {
    active = is_session_valid(),
    visible = ollama_session.is_visible,
    model = ollama_session.model,
    pane_id = ollama_session.pane_id,
    buffer_id = ollama_session.buffer_id,
  }
end

-- Interactive API chat state
local api_chat = {
  buffer_id = nil,
  model = nil,
  conversation = {}, -- Store the full conversation context
}

-- Open interactive API chat with initial context
function M.open_api_chat(initial_message)
  local current_model = get_current_model()
  if not current_model then
    vim.notify("Cannot start API chat: no model available", vim.log.levels.ERROR)
    return
  end
  
  -- Create or reuse chat buffer
  if not api_chat.buffer_id or not vim.api.nvim_buf_is_valid(api_chat.buffer_id) then
    api_chat.buffer_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(api_chat.buffer_id, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(api_chat.buffer_id, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(api_chat.buffer_id, 'modifiable', true)
    
    -- Set buffer name
    local timestamp = os.date("%H%M%S")
    local success, err = pcall(vim.api.nvim_buf_set_name, api_chat.buffer_id, "Ollama-Chat-" .. timestamp)
    if not success then
      vim.notify("Failed to set chat buffer name: " .. err, vim.log.levels.WARN)
    end
    
    -- Initialize conversation with system message if this is the first message
    api_chat.conversation = {
      {
        role = "system",
        content = "You are a helpful coding assistant. You have context loaded and should answer questions about the code concisely."
      }
    }
  end
  
  api_chat.model = current_model
  
  -- Add the initial context message to conversation and display
  table.insert(api_chat.conversation, { role = "assistant", content = initial_message })
  
  -- Open the chat buffer in a split
  local config = ollama_manager.load_config() or {}
  local split_preference = config.split_preference or "horizontal"
  local split_cmd = (split_preference == "vertical") and "vsplit" or "split"
  vim.cmd(split_cmd)
  vim.api.nvim_win_set_buf(0, api_chat.buffer_id)
  
  -- Display the conversation
  update_chat_display()
  
  -- Set up keybindings for the chat buffer
  setup_chat_keybindings()
end

-- Update chat buffer display with current conversation
local function update_chat_display()
  if not api_chat.buffer_id or not vim.api.nvim_buf_is_valid(api_chat.buffer_id) then
    return
  end
  
  local lines = {}
  
  -- Add conversation history
  for _, message in ipairs(api_chat.conversation) do
    if message.role == "assistant" then
      table.insert(lines, "🤖 " .. message.content)
      table.insert(lines, "")
    elseif message.role == "user" then
      table.insert(lines, "👤 " .. message.content)
      table.insert(lines, "")
    end
  end
  
  -- Add input prompt
  table.insert(lines, "---")
  table.insert(lines, "💬 Type your question and press <CR> to send:")
  table.insert(lines, "")
  
  -- Update buffer
  vim.api.nvim_buf_set_option(api_chat.buffer_id, 'modifiable', true)
  vim.api.nvim_buf_set_lines(api_chat.buffer_id, 0, -1, false, lines)
  
  -- Move cursor to end for typing
  local line_count = #lines
  vim.api.nvim_win_set_cursor(0, {line_count, 0})
end

-- Set up keybindings for interactive chat
local function setup_chat_keybindings()
  if not api_chat.buffer_id then return end
  
  -- Send message on Enter
  vim.api.nvim_buf_set_keymap(api_chat.buffer_id, 'n', '<CR>', 
    ':lua require("vinod.ollama_chat").send_chat_message()<CR>', 
    { noremap = true, silent = true })
    
  -- Also allow in insert mode  
  vim.api.nvim_buf_set_keymap(api_chat.buffer_id, 'i', '<CR>', 
    '<Esc>:lua require("vinod.ollama_chat").send_chat_message()<CR>', 
    { noremap = true, silent = true })
end

-- Send a message from the chat buffer
function M.send_chat_message()
  if not api_chat.buffer_id or not vim.api.nvim_buf_is_valid(api_chat.buffer_id) then
    vim.notify("No active chat session", vim.log.levels.ERROR)
    return
  end
  
  -- Get current line as the user's message
  local current_line = vim.api.nvim_get_current_line()
  if vim.trim(current_line) == "" then
    vim.notify("Please type a message first", vim.log.levels.WARN)
    return
  end
  
  local user_message = vim.trim(current_line)
  
  -- Add user message to conversation
  table.insert(api_chat.conversation, { role = "user", content = user_message })
  
  -- Show "thinking" indicator
  vim.api.nvim_buf_set_option(api_chat.buffer_id, 'modifiable', true)
  local lines = vim.api.nvim_buf_get_lines(api_chat.buffer_id, 0, -1, false)
  lines[#lines] = "🤔 Thinking..."
  vim.api.nvim_buf_set_lines(api_chat.buffer_id, 0, -1, false, lines)
  
  -- Send to API
  send_api_message(user_message)
end

-- Send message to Ollama API and handle response
local function send_api_message(user_message)
  local curl = require('plenary.curl')
  
  -- Prepare API payload with full conversation context
  local payload = {
    model = api_chat.model,
    messages = api_chat.conversation,
    stream = false
  }
  
  curl.post('http://localhost:11434/api/chat', {
    headers = {
      ['Content-Type'] = 'application/json',
    },
    body = vim.fn.json_encode(payload),
    callback = function(out)
      vim.schedule(function()
        if out.status == 200 and out.body then
          -- Process response
          local response_lines = {}
          for line in out.body:gmatch("[^\n]+") do
            local success, response = pcall(vim.fn.json_decode, line)
            if success and response.message and response.message.content then
              table.insert(response_lines, response.message.content)
            end
          end
          
          if #response_lines > 0 then
            local assistant_response = table.concat(response_lines, "")
            -- Add to conversation
            table.insert(api_chat.conversation, { role = "assistant", content = assistant_response })
            -- Update display
            update_chat_display()
          else
            vim.notify("No valid response received", vim.log.levels.WARN)
          end
        else
          vim.notify("API Error: " .. out.status .. " - " .. (out.body or "Unknown error"), vim.log.levels.ERROR)
        end
      end)
    end,
    on_error = function(err)
      vim.schedule(function()
        vim.notify("Request failed: " .. vim.inspect(err), vim.log.levels.ERROR)
      end)
    end
  })
end

return M
