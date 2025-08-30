-- Lightweight Ollama integration with CopilotChat.nvim
-- Uses CopilotChat's built-in selection system for proper context handling

local M = {}

-- Send current buffer content to CopilotChat using proper selection system
function M.send_buffer_context()
  -- Check if buffer has content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if vim.trim(table.concat(lines, '\n')) == '' then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  -- Get filename for personalized prompt
  local filename = vim.api.nvim_buf_get_name(0)
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"
  
  local prompt = string.format(
    "I've loaded the file '%s' for analysis. Please acknowledge you have the context and are ready for questions about this code.",
    display_name
  )

  -- Use CopilotChat's proper selection system
  require('CopilotChat').ask(prompt, {
    selection = require('CopilotChat.select').buffer
  })
end

-- Send visual selection to CopilotChat using proper selection system
function M.send_visual_selection()
  -- Get filename for personalized prompt
  local filename = vim.api.nvim_buf_get_name(0)
  local display_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"
  
  local prompt = string.format(
    "I've selected a portion from file '%s' for analysis. Please acknowledge you have the context and are ready for questions about this code selection.",
    display_name
  )

  -- Use CopilotChat's proper selection system
  require('CopilotChat').ask(prompt, {
    selection = require('CopilotChat.select').visual
  })
end

return M