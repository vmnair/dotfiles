-- fzf-lua integration for Vinod's Todo Manager
-- Provides modern fuzzy finder interface for todo filtering and management
-- Fallback to custom buffer system if fzf-lua not available

local M = {}

-- Check if fzf-lua is available
local has_fzf, fzf = pcall(require, 'fzf-lua')
if not has_fzf then
  -- Graceful fallback - return empty module
  print("fzf-lua not available, falling back to custom buffer system")
  return M
end

local todo_manager = require('vinod.todo_manager')

-- Create a formatted entry for fzf display
-- Returns: display_text, todo_object, line_number
local function format_todo_for_fzf(todo, line_num, file_path)
  local display_text = ""
  
  -- Status indicator
  local status = todo.completed and "✓" or " "
  display_text = "[" .. status .. "] "
  
  -- Category icon
  if todo.category and todo.category ~= "" then
    local icon = todo_manager.config.category_icons[todo.category] or "📝"
    display_text = display_text .. icon .. " "
  end
  
  -- Description
  display_text = display_text .. todo.description
  
  -- Due date with color coding info
  if todo.due_date and todo.due_date ~= "" then
    local due_indicator = ""
    if todo_manager.is_past_due and todo_manager.is_past_due(todo.due_date) then
      due_indicator = " [OVERDUE: " .. todo.due_date .. "]"
    elseif todo_manager.is_due_today and todo_manager.is_due_today(todo.due_date) then
      due_indicator = " [DUE TODAY: " .. todo.due_date .. "]"
    else
      due_indicator = " [Due: " .. todo.due_date .. "]"
    end
    display_text = display_text .. due_indicator
  end
  
  -- Tags
  if #todo.tags > 0 then
    display_text = display_text .. " #" .. table.concat(todo.tags, " #")
  end
  
  -- Add line number and file info for navigation
  display_text = display_text .. " │ " .. (file_path:match("([^/]+)$") or "todo") .. ":" .. line_num
  
  return display_text, todo, line_num, file_path
end

-- Get all todos from current buffer with their line numbers
local function get_todos_from_current_buffer()
  local current_file = vim.api.nvim_buf_get_name(0)
  local total_lines = vim.api.nvim_buf_line_count(0)
  local todos = {}
  
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    if line then
      local todo = todo_manager.parse_todo_line(line)
      if todo then
        local display_text, todo_obj, line_number, file_path = format_todo_for_fzf(todo, line_num, current_file)
        table.insert(todos, {
          display = display_text,
          todo = todo_obj,
          line_num = line_number,
          file_path = file_path,
          original_line = line
        })
      end
    end
  end
  
  return todos
end

-- Generic fzf todo picker with custom filter function
local function fzf_todo_picker(title, filter_fn, opts)
  opts = opts or {}
  
  -- Get all todos from current buffer
  local all_todos = get_todos_from_current_buffer()
  
  -- Apply filter function if provided
  local filtered_todos = filter_fn and filter_fn(all_todos) or all_todos
  
  if #filtered_todos == 0 then
    print("No " .. (title:lower()) .. " found")
    return
  end
  
  -- Prepare entries for fzf
  local entries = {}
  for _, item in ipairs(filtered_todos) do
    table.insert(entries, item.display)
  end
  
  -- Default fzf options
  local fzf_opts = {
    prompt = title .. " ❯ ",
    preview = false, -- Can be enabled later for todo details
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          -- Find the corresponding todo item
          local selected_text = selected[1]
          for _, item in ipairs(filtered_todos) do
            if item.display == selected_text then
              -- Navigate to the original file and line
              vim.cmd.edit(vim.fn.fnameescape(item.file_path))
              vim.api.nvim_win_set_cursor(0, {item.line_num, 0})
              return
            end
          end
        end
      end,
      ['ctrl-t'] = function(selected)
        if #selected > 0 then
          -- Toggle completion
          local selected_text = selected[1]
          for _, item in ipairs(filtered_todos) do
            if item.display == selected_text then
              vim.cmd.edit(vim.fn.fnameescape(item.file_path))
              vim.api.nvim_win_set_cursor(0, {item.line_num, 0})
              todo_manager.toggle_todo_on_line()
              return
            end
          end
        end
      end
    },
    fzf_opts = {
      ['--header'] = 'Enter: Navigate | Ctrl-T: Toggle completion',
      ['--info'] = 'inline',
    }
  }
  
  -- Merge with custom options
  for k, v in pairs(opts) do
    fzf_opts[k] = v
  end
  
  fzf.fzf_exec(entries, fzf_opts)
end

-- Filter todos by category
function M.filter_by_category(category)
  if not category then
    print("Error: Category is required")
    return
  end
  
  local filter_fn = function(todos)
    local filtered = {}
    for _, item in ipairs(todos) do
      if item.todo.category and item.todo.category:lower() == category:lower() then
        table.insert(filtered, item)
      end
    end
    return filtered
  end
  
  local category_icon = todo_manager.config.category_icons[category] or "📝"
  fzf_todo_picker(category_icon .. " " .. category .. " Todos", filter_fn)
end

-- Filter todos with due dates
function M.filter_by_due_dates()
  local filter_fn = function(todos)
    local filtered = {}
    for _, item in ipairs(todos) do
      if item.todo.due_date and item.todo.due_date ~= "" then
        table.insert(filtered, item)
      end
    end
    return filtered
  end
  
  fzf_todo_picker("📅 Due Date Todos", filter_fn)
end

-- Filter todos due today
function M.filter_by_today()
  local filter_fn = function(todos)
    local filtered = {}
    for _, item in ipairs(todos) do
      if item.todo.due_date and item.todo.due_date ~= "" then
        if todo_manager.is_due_today and todo_manager.is_due_today(item.todo.due_date) then
          table.insert(filtered, item)
        end
      end
    end
    return filtered
  end
  
  fzf_todo_picker("📋 Today's Todos", filter_fn)
end

-- Filter todos due today and past due
function M.filter_by_today_and_past_due()
  local filter_fn = function(todos)
    local filtered = {}
    for _, item in ipairs(todos) do
      if item.todo.due_date and item.todo.due_date ~= "" then
        local is_today = todo_manager.is_due_today and todo_manager.is_due_today(item.todo.due_date)
        local is_past_due = todo_manager.is_past_due and todo_manager.is_past_due(item.todo.due_date)
        if is_today or is_past_due then
          table.insert(filtered, item)
        end
      end
    end
    return filtered
  end
  
  fzf_todo_picker("⚠️  Urgent Todos", filter_fn)
end

-- Show all todos (no filtering)
function M.show_all()
  fzf_todo_picker("📝 All Todos", nil)
end

-- Quick category selection for specific categories
function M.filter_medicine()
  M.filter_by_category("Medicine")
end

function M.filter_personal()
  M.filter_by_category("Personal")
end

function M.filter_oms()
  M.filter_by_category("OMS")
end

-- Interactive category picker
function M.pick_category()
  local categories = todo_manager.config.categories
  local entries = {}
  
  for _, category in ipairs(categories) do
    local icon = todo_manager.config.category_icons[category] or "📝"
    table.insert(entries, icon .. " " .. category)
  end
  
  fzf.fzf_exec(entries, {
    prompt = "Choose Category ❯ ",
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local category = selected[1]:match("^.* (.+)$") -- Extract category name after icon
          M.filter_by_category(category)
        end
      end
    }
  })
end

-- Enhanced todo creation with fzf assistance
function M.quick_add()
  -- Step 1: Category selection
  local categories = todo_manager.config.categories
  local category_entries = {}
  
  for _, category in ipairs(categories) do
    local icon = todo_manager.config.category_icons[category] or "📝"
    table.insert(category_entries, icon .. " " .. category)
  end
  
  fzf.fzf_exec(category_entries, {
    prompt = "Select Category ❯ ",
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local category = selected[1]:match("^.* (.+)$")
          
          -- Step 2: Get description
          vim.ui.input({prompt = "Todo description: "}, function(description)
            if description and description ~= "" then
              -- Step 3: Due date options
              local due_options = {
                "No due date",
                "Today",
                "Tomorrow", 
                "Next Monday",
                "Next Week",
                "Custom (calendar picker)"
              }
              
              fzf.fzf_exec(due_options, {
                prompt = "Due Date ❯ ",
                actions = {
                  ['default'] = function(due_selected)
                    if #due_selected > 0 then
                      local due_choice = due_selected[1]
                      local due_date = ""
                      
                      if due_choice == "Today" then
                        due_date = os.date("%m-%d-%Y")
                      elseif due_choice == "Tomorrow" then
                        due_date = os.date("%m-%d-%Y", os.time() + 24*60*60)
                      elseif due_choice == "Next Monday" then
                        local t = os.date("*t")
                        local days_until_monday = (9 - t.wday) % 7
                        if days_until_monday == 0 then days_until_monday = 7 end
                        due_date = os.date("%m-%d-%Y", os.time() + days_until_monday*24*60*60)
                      elseif due_choice == "Next Week" then
                        due_date = os.date("%m-%d-%Y", os.time() + 7*24*60*60)
                      elseif due_choice == "Custom (calendar picker)" then
                        todo_manager.get_date_input(function(picked_date)
                          if picked_date then
                            due_date = picked_date
                          end
                          local success = todo_manager.add_todo(description, category, {}, due_date)
                          if success then
                            print("✓ Todo added: " .. description .. " (" .. category .. ")")
                          end
                        end)
                        return
                      end
                      
                      -- Add the todo
                      local success = todo_manager.add_todo(description, category, {}, due_date)
                      if success then
                        local due_display = due_date ~= "" and " [Due: " .. due_date .. "]" or ""
                        print("✓ Todo added: " .. description .. " (" .. category .. ")" .. due_display)
                      end
                    end
                  end
                }
              })
            end
          end)
        end
      end
    }
  })
end

return M