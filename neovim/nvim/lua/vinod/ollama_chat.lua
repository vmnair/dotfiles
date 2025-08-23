local M = {}
local ollama_manager = require("vinod.ollama_manager")
local ollama_ui = require("vinod.ollama_ui")

-- Module state for tracking ollama sessions
local ollama_session = {
  pane_id = nil,     -- tmux pane ID or Neovim buffer number
  model = nil,       -- current model being used
  process_id = nil,  -- ollama process ID
  is_visible = false, -- current visibility state
  buffer_id = nil,   -- neovim buffer id for chat
  job_id = nil,      -- neovim job id
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

-- Send current buffer content to ollama as context
function M.send_buffer_context()
  if not is_session_valid() then
    vim.notify("No active ollama session. Use ,oo to start one.", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.api.nvim_buf_get_name(buf)

  -- Get just the filename, not the full path
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"

  local context_msg = string.format(
    "Here's the current buffer (%s):\n\n```\n%s\n```\n\nPlease analyze this code.",
    display_name,
    content
  )

  -- Send to ollama session
  if is_in_tmux() and ollama_session.pane_id then
    -- For tmux, we need to be more careful with special characters
    local temp_file = vim.fn.tempname()
    local file = io.open(temp_file, "w")
    if file then
      file:write(context_msg)
      file:close()
      local send_cmd = string.format('tmux send-keys -t %s "$(cat %s)" C-m', ollama_session.pane_id, temp_file)
      os.execute(send_cmd)
      os.remove(temp_file)
      vim.notify("Buffer content sent to ollama", vim.log.levels.INFO)
    else
      vim.notify("Failed to create temp file for context", vim.log.levels.ERROR)
    end
  elseif ollama_session.job_id then
    vim.fn.chansend(ollama_session.job_id, context_msg .. "\n")
    vim.notify("Buffer content sent to ollama", vim.log.levels.INFO)
  end
end

-- Send visual selection to ollama as context
function M.send_visual_selection()
  if not is_session_valid() then
    vim.notify("No active ollama session. Use ,oo to start one.", vim.log.levels.WARN)
    return
  end

  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
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
  local filename = vim.api.nvim_buf_get_name(0)
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"

  local context_msg = string.format(
    "Here's the selected code from %s:\n\n```\n%s\n```\n\nPlease review this selection.",
    display_name,
    content
  )

  -- Send to ollama session
  if is_in_tmux() and ollama_session.pane_id then
    -- For tmux, use temp file approach
    local temp_file = vim.fn.tempname()
    local file = io.open(temp_file, "w")
    if file then
      file:write(context_msg)
      file:close()
      local send_cmd = string.format('tmux send-keys -t %s "$(cat %s)" C-m', ollama_session.pane_id, temp_file)
      os.execute(send_cmd)
      os.remove(temp_file)
      vim.notify("Selection sent to ollama", vim.log.levels.INFO)
    else
      vim.notify("Failed to create temp file for context", vim.log.levels.ERROR)
    end
  elseif ollama_session.job_id then
    vim.fn.chansend(ollama_session.job_id, context_msg .. "\n")
    vim.notify("Selection sent to ollama", vim.log.levels.INFO)
  end
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

return M

