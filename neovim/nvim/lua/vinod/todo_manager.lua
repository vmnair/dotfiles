local M = {}

-- ========================================
-- CONFIGURATION
-- ========================================

M.config = {
  todo_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo",
  notebook_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook", -- zk notebook directory
  active_file = "active-todos.md",
  completed_file = "completed-todos.md",
  categories = { "Medicine", "OMS", "Personal" },
  date_format = "%m-%d-%Y", -- mm-dd-YYYY format as requested
  category_icons = {
    Medicine = "💊",
    OMS = "🛠️",
    Personal = "🏡",
  },
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Get current date in mm-dd-yyyy format
local function get_current_date()
  return os.date(M.config.date_format)
end

-- Check if a date is past due
local function is_past_due(date_str)
  if not date_str or date_str == "" then
    return false
  end

  -- Parse the date string (mm-dd-yyyy)
  local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
  if not month or not day or not year then
    return false
  end

  -- Convert to timestamp for comparison
  local year_num, month_num, day_num = tonumber(year), tonumber(month), tonumber(day)
  if not year_num or not month_num or not day_num then
    return false
  end

  local due_time = os.time({
    year = year_num,
    month = month_num,
    day = day_num,

    -- Set to end of day to give users full day to complete
    hour = 23,
    min = 59,
    sec = 59,
  })

  local current_time = os.time()
  return current_time > due_time
end

-- Check if a date is due today
local function is_due_today(date_str)
  if not date_str or date_str == "" then
    return false
  end

  -- Parse the date string (mm-dd-yyyy)
  local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
  if not month or not day or not year then
    return false
  end

  -- Convert to timestamp for comparison
  local year_num, month_num, day_num = tonumber(year), tonumber(month), tonumber(day)
  if not year_num or not month_num or not day_num then
    return false
  end

  -- Get today's date components
  local today = os.date("*t")

  -- Compare year, month, and day
  return year_num == today.year and month_num == today.month and day_num == today.day
end

-- Get full file path for todo files
local function get_file_path(filename)
  return M.config.todo_dir .. "/" .. filename
end

-- ========================================
-- TODO PARSING AND FORMATTING
-- ========================================

-- Parse a todo line into components
-- Supports both legacy pipe format and current clean format
-- Returns: todo table or nil if invalid
function M.parse_todo_line(line)
  if not line or line == "" then
    return nil
  end

  -- Check if line is a todo item using markdown checkbox pattern
  local checkbox_pattern = "^%s*%- %[([%sx])%]%s*(.+)$"
  local checkbox, content = line:match(checkbox_pattern)

  if not checkbox or not content then
    return nil
  end

  local todo = {
    completed = (checkbox:lower() == "x"),
    description = "",
    category = "",
    tags = {},
    due_date = "",
    added_date = "",
    completion_date = "",
    raw_line = line,
  }

  -- Check if this is the old pipe format or new clean format
  if content:find("|") then
    -- Old pipe format parsing
    local parts = {}
    for part in content:gmatch("[^|]+") do
      table.insert(parts, part:match("^%s*(.-)%s*$"))
    end

    todo.description = parts[1] or ""

    for i = 2, #parts do
      local part = parts[i]
      local category = part:match("^Category:%s*(.+)$")
      if category then
        todo.category = category
      end

      local tags_content = part:match("^Tags:%s*(.+)$")
      if tags_content then
        for tag in tags_content:gmatch("#(%w+)") do
          table.insert(todo.tags, tag)
        end
      end

      local due_date = part:match("^Due:%s*(.+)$")
      if due_date then
        todo.due_date = due_date
      end

      local added_date = part:match("^Added:%s*(.+)$")
      if added_date then
        todo.added_date = added_date
      end

      local completion_date = part:match("^Completed:%s*(.+)$")
      if completion_date then
        todo.completion_date = completion_date
      end
    end
  else
    -- New clean format parsing
    local remaining = content

    -- Extract dates in parentheses (subtle dates)
    local date_paren = remaining:match("%(([^%)]+)%)")
    if date_paren then
      -- Check if it looks like a date (contains dashes and numbers)
      if date_paren:match("%d+%-%d+%-%d+") then
        if todo.completed then
          todo.completion_date = date_paren
        else
          todo.added_date = date_paren
        end
        remaining = remaining:gsub("%(([^%)]+)%)", "")
      end
    end

    -- Extract due date
    local due_date = remaining:match("%[Due:%s*([^%]]+)%]")
    if due_date then
      todo.due_date = due_date
      remaining = remaining:gsub("%[Due:%s*[^%]]+%]", "")
    end

    -- Extract tags
    for tag in remaining:gmatch("#(%w+)") do
      table.insert(todo.tags, tag)
    end
    remaining = remaining:gsub("#%w+", "")

    -- Extract category by matching against known icons (could be at start or anywhere)
    for category, icon in pairs(M.config.category_icons) do
      if remaining:find(icon, 1, true) then
        todo.category = category
        remaining = remaining:gsub(vim.pesc(icon), "")
        break
      end
    end

    -- What's left should be the description (trim whitespace)
    todo.description = remaining:match("^%s*(.-)%s*$") or ""
  end

  return todo
end

-- Format todo object into markdown line
function M.format_todo_line(todo)
  local checkbox = todo.completed and "[x]" or "[ ]"
  local line = "- " .. checkbox

  -- Add category icon right after checkbox (streamlined appearance)
  if todo.category and todo.category ~= "" then
    local icon = M.config.category_icons[todo.category] or "📝"
    line = line .. " " .. icon
  end

  -- Add description
  line = line .. " " .. todo.description

  -- Add due date if present (prioritized)
  if todo.due_date and todo.due_date ~= "" then
    line = line .. " [Due: " .. todo.due_date .. "]"
  end

  -- Add tags if present (no pipes, no "Tags:" label)
  if #todo.tags > 0 then
    for _, tag in ipairs(todo.tags) do
      line = line .. " #" .. tag
    end
  end

  -- Add completion date for completed todos (subtle, no "Completed:" label)
  if todo.completion_date and todo.completion_date ~= "" then
    line = line .. " (" .. todo.completion_date .. ")"
  end

  return line
end

-- ========================================
-- FILE OPERATIONS
-- ========================================

-- Read and parse todos from file
function M.read_todos_from_file(filename)
  local file_path = get_file_path(filename)
  local file = io.open(file_path, "r")

  if not file then
    return {}
  end

  local todos = {}
  for line in file:lines() do
    local todo = M.parse_todo_line(line)
    if todo then
      table.insert(todos, todo)
    end
  end

  file:close()
  return todos
end

-- Write todos to file with header
function M.write_todos_to_file(filename, todos, header)
  local file_path = get_file_path(filename)
  local file = io.open(file_path, "w")

  if not file then
    error("Could not open file for writing: " .. file_path)
    return false
  end

  -- Write header if provided
  if header then
    file:write(header .. "\n\n")
  end

  -- Write each todo
  for _, todo in ipairs(todos) do
    file:write(M.format_todo_line(todo) .. "\n")
  end

  file:close()
  return true
end

-- Get all active todos from file
function M.get_active_todos()
  local all_todos = M.read_todos_from_file(M.config.active_file)
  local active_todos = {}

  -- Only return todos that are not completed
  for _, todo in ipairs(all_todos) do
    if not todo.completed then
      table.insert(active_todos, todo)
    end
  end

  return active_todos
end

-- Get all completed todos from file
function M.get_completed_todos()
  return M.read_todos_from_file(M.config.completed_file)
end

-- ========================================
-- TODO MANAGEMENT
-- ========================================

-- Add new todo to active file
function M.add_todo(description, category, tags, due_date)
  -- Save any unsaved changes to the active todos buffer before proceeding
  M.save_active_todos_buffer_if_modified()

  -- Default to "Personal" category if none provided
  if not category or category == "" then
    category = "Personal"
  end

  -- Validate category
  if category and not vim.tbl_contains(M.config.categories, category) then
    error("Invalid category. Must be one of: " .. table.concat(M.config.categories, ", "))
    return false
  end

  local todo = {
    completed = false,
    description = description,
    category = category,
    tags = tags or {},
    due_date = due_date or "",
    added_date = get_current_date(),
    completion_date = "",
    raw_line = "",
  }

  -- Get existing todos
  local todos = M.get_active_todos()
  table.insert(todos, todo)

  -- Write back to file
  local header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
  local success = M.write_todos_to_file(M.config.active_file, todos, header)

  if success then
    -- Check if active todos file is currently open and refresh it
    M.refresh_active_todos_if_open()
  end

  return success
end

-- Save active todos buffer if modified
function M.save_active_todos_buffer_if_modified()
  local active_file_path = get_file_path(M.config.active_file)

  -- Check all buffers to see if the active todos file is open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == active_file_path then
        -- Check if buffer has unsaved changes
        if vim.api.nvim_buf_get_option(buf, "modified") then
          -- Save the buffer silently (suppress "file written" message)
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent write")
          end)
          return true
        end
      end
    end
  end

  return false
end

-- Refresh active todos file if open
function M.refresh_active_todos_if_open()
  local active_file_path = get_file_path(M.config.active_file)

  -- Check all buffers to see if the active todos file is open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == active_file_path then
        -- Get all windows showing this buffer
        local windows = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            table.insert(windows, win)
          end
        end

        if #windows > 0 then
          -- Save cursor position from the first window
          local cursor_pos = vim.api.nvim_win_get_cursor(windows[1])

          -- Reload the buffer content
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("checktime") -- Check if file has been modified
            vim.cmd("e!")  -- Force reload from disk
          end)

          -- Restore cursor position in all windows
          for _, win in ipairs(windows) do
            vim.api.nvim_win_set_cursor(win, cursor_pos)
          end

          -- Reapply syntax highlighting including due date colors
          vim.api.nvim_buf_call(buf, function()
            M.setup_todo_syntax()
          end)

          return true
        end
      end
    end
  end

  return false
end

-- Complete todo and move to completed file
function M.complete_todo(index)
  local active_todos = M.get_active_todos()

  if index < 1 or index > #active_todos then
    error("Invalid todo index: " .. index)
    return false
  end

  -- Get the todo to complete
  local todo = active_todos[index]
  todo.completed = true
  todo.completion_date = get_current_date()

  -- Add to completed todos first
  local completed_todos = M.get_completed_todos()
  table.insert(completed_todos, todo)

  -- Remove from active todos (after adding to completed)
  table.remove(active_todos, index)

  -- Write both files
  local active_header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
  local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"

  local success1 = M.write_todos_to_file(M.config.active_file, active_todos, active_header)
  local success2 = M.write_todos_to_file(M.config.completed_file, completed_todos, completed_header)

  if success1 and success2 then
    -- Refresh active todos file if it's currently open
    M.refresh_active_todos_if_open()
  end

  return success1 and success2
end

-- Delete todo permanently from active file
function M.delete_todo(index)
  local active_todos = M.get_active_todos()

  if index < 1 or index > #active_todos then
    error("Invalid todo index: " .. index)
    return false
  end

  -- Remove from active todos
  table.remove(active_todos, index)

  -- Write back to file
  local header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
  local success = M.write_todos_to_file(M.config.active_file, active_todos, header)

  if success then
    -- Refresh active todos file if it's currently open
    M.refresh_active_todos_if_open()
  end

  return success
end

-- Clean up completed todos in active file and fix missing dates
function M.cleanup_completed_todos()
  local all_todos_in_active = M.read_todos_from_file(M.config.active_file)
  local truly_active = {}
  local completed_in_active = {}

  -- Separate active and completed todos
  for _, todo in ipairs(all_todos_in_active) do
    if todo.completed then
      -- Add completion date if missing
      if not todo.completion_date or todo.completion_date == "" then
        todo.completion_date = get_current_date()
      end
      table.insert(completed_in_active, todo)
    else
      -- Add added date if missing (for older todos)
      if not todo.added_date or todo.added_date == "" then
        todo.added_date = get_current_date()
      end
      table.insert(truly_active, todo)
    end
  end

  -- If we found completed todos in active file, move them
  if #completed_in_active > 0 then
    local existing_completed = M.get_completed_todos()

    -- Add the completed todos to the completed list
    for _, todo in ipairs(completed_in_active) do
      table.insert(existing_completed, todo)
    end

    -- Write both files
    local active_header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
    local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"

    M.write_todos_to_file(M.config.active_file, truly_active, active_header)
    M.write_todos_to_file(M.config.completed_file, existing_completed, completed_header)
  end
end

-- Initialize todo system - create files and directories
function M.init_todo_files()
  -- Create todo directory if it doesn't exist
  vim.fn.mkdir(M.config.todo_dir, "p")

  -- Create active todos file if it doesn't exist
  local active_path = get_file_path(M.config.active_file)
  if vim.fn.filereadable(active_path) == 0 then
    local header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
    M.write_todos_to_file(M.config.active_file, {}, header)
  end

  -- Create completed todos file if it doesn't exist
  local completed_path = get_file_path(M.config.completed_file)
  if vim.fn.filereadable(completed_path) == 0 then
    local header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
    M.write_todos_to_file(M.config.completed_file, {}, header)
  end

  -- Clean up any completed todos that might be in the active file
  M.cleanup_completed_todos()
end

-- ========================================
-- DISPLAY AND FILTERING
-- ========================================

-- Get display icon for todo category
local function get_display_icon(todo)
  if not todo.category or todo.category == "" then
    return "📝"
  end
  return M.config.category_icons[todo.category] or "📝"
end

-- Display todos in formatted list
function M.display_todos(todos, title)
  if #todos == 0 then
    print(title .. ": No todos found")
    return
  end

  print("\n" .. title .. ":")
  print(string.rep("=", #title + 1))

  for i, todo in ipairs(todos) do
    local status = todo.completed and "[✓]" or "[ ]"
    local line = string.format("%d. %s %s", i, status, todo.description)

    -- Add category icon instead of text in parentheses (only if not already present)
    local icon = get_display_icon(todo)
    if icon ~= "" then
      line = line .. " " .. icon
    end

    -- Add due date (more prominent than other dates)
    if todo.due_date and todo.due_date ~= "" then
      line = line .. " [Due: " .. todo.due_date .. "]"
    end

    -- Add tags
    if #todo.tags > 0 then
      line = line .. " #" .. table.concat(todo.tags, " #")
    end

    -- Only show completion date for completed todos (remove added date from display)
    if todo.completion_date and todo.completion_date ~= "" then
      line = line .. " [Completed: " .. todo.completion_date .. "]"
    end

    print(line)
  end
  print("")
end

-- Filter todos by category
function M.filter_todos_by_category(todos, category)
  if not category or category == "" then
    return todos
  end

  local filtered = {}
  for _, todo in ipairs(todos) do
    if todo.category:lower() == category:lower() then
      table.insert(filtered, todo)
    end
  end

  return filtered
end

-- Filter todos with due dates
function M.filter_todos_with_due_dates(todos)
  local filtered = {}
  for _, todo in ipairs(todos) do
    if todo.due_date and todo.due_date ~= "" then
      table.insert(filtered, todo)
    end
  end
  return filtered
end

-- Filter past due todos
function M.filter_past_due_todos(todos)
  local filtered = {}
  for _, todo in ipairs(todos) do
    if todo.due_date and todo.due_date ~= "" and is_past_due(todo.due_date) then
      table.insert(filtered, todo)
    end
  end
  return filtered
end

-- Filter todos due today
function M.filter_today_todos(todos)
  local filtered = {}
  for _, todo in ipairs(todos) do
    if todo.due_date and todo.due_date ~= "" and is_due_today(todo.due_date) then
      table.insert(filtered, todo)
    end
  end
  return filtered
end

-- Filter urgent todos (today or past due)
function M.filter_today_and_past_due_todos(todos)
  local filtered = {}
  for _, todo in ipairs(todos) do
    if todo.due_date and todo.due_date ~= "" and (is_due_today(todo.due_date) or is_past_due(todo.due_date)) then
      table.insert(filtered, todo)
    end
  end
  return filtered
end

-- List active todos with optional category filter
function M.list_active_todos(category)
  local todos = M.get_active_todos()

  if category then
    todos = M.filter_todos_by_category(todos, category)
    M.display_todos(todos, "Active Todos - " .. category .. " Category")
  else
    M.display_todos(todos, "Active Todos")
  end
end

-- List completed todos with optional category filter
function M.list_completed_todos(category)
  local todos = M.get_completed_todos()

  if category then
    todos = M.filter_todos_by_category(todos, category)
    M.display_todos(todos, "Completed Todos - " .. category .. " Category")
  else
    M.display_todos(todos, "Completed Todos")
  end
end

-- List todos with due dates
function M.list_due_todos()
  local todos = M.get_active_todos()
  local due_todos = M.filter_todos_with_due_dates(todos)
  M.display_todos(due_todos, "Todos with Due Dates")
end

-- List past due todos
function M.list_past_due_todos()
  local todos = M.get_active_todos()
  local past_due_todos = M.filter_past_due_todos(todos)
  M.display_todos(past_due_todos, "Past Due Todos")
end

-- List todos due today
function M.list_today_todos()
  local todos = M.get_active_todos()
  local today_todos = M.filter_today_todos(todos)
  M.display_todos(today_todos, "Todos Due Today")
end

-- List urgent todos
function M.list_today_and_past_due_todos()
  local todos = M.get_active_todos()
  local urgent_todos = M.filter_today_and_past_due_todos(todos)
  M.display_todos(urgent_todos, "Today & Past Due Todos")
end

-- Show category overview with active and completed todos
function M.list_todos_by_category(category)
  if not category or category == "" then
    print("Error: Category is required")
    return
  end

  -- Validate category
  if not vim.tbl_contains(M.config.categories, category) then
    print("Invalid category. Must be one of: " .. table.concat(M.config.categories, ", "))
    return
  end

  local active_todos = M.get_active_todos()
  local completed_todos = M.get_completed_todos()

  local active_filtered = M.filter_todos_by_category(active_todos, category)
  local completed_filtered = M.filter_todos_by_category(completed_todos, category)

  print("\n" .. category .. " Category Overview:")
  print(string.rep("=", #category + 18))

  if #active_filtered > 0 then
    M.display_todos(active_filtered, "Active " .. category .. " Todos")
  else
    print("\nActive " .. category .. " Todos: No todos found\n")
  end

  if #completed_filtered > 0 then
    M.display_todos(completed_filtered, "Completed " .. category .. " Todos")
  else
    print("Completed " .. category .. " Todos: No todos found\n")
  end

  -- Show summary
  print("Summary: " .. #active_filtered .. " active, " .. #completed_filtered .. " completed")
end

-- ========================================
-- ZK INTEGRATION
-- ========================================

-- Get available directories in notebook for note filing
local function get_notebook_directories()
  local notebook_path = M.config.notebook_dir
  local directories = {}
  
  -- Use find command to get all directories up to 3 levels deep
  local cmd = string.format('find "%s" -maxdepth 3 -type d -not -path "*/.*" | sort', notebook_path)
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      -- Remove the notebook path prefix to get relative paths
      local dir = line:gsub("^" .. vim.pesc(notebook_path) .. "/", "")
      -- Skip the notebook root directory itself and hidden directories
      if dir ~= line and dir ~= "" and not dir:match("^%.") then
        table.insert(directories, dir)
      end
    end
    handle:close()
  end
  
  return directories
end

-- Map todo categories to likely directories
local function suggest_directory_for_category(category)
  local category_mapping = {
    Medicine = "healthcare/cardiology", -- Default to cardiology for medicine
    OMS = "oms/admin/discussions", 
    Personal = "journal"
  }
  
  return category_mapping[category] or "research" -- default to research
end

-- Create zk note from todo on current line
function M.create_note_from_todo()
  local line = vim.api.nvim_get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- Check if current line is a todo
  local todo = M.parse_todo_line(line)
  if not todo then
    print("Current line is not a todo item")
    return false
  end

  -- Extract clean description for note title
  local description = todo.description:gsub("^%s+", ""):gsub("%s+$", "")
  if description == "" then
    print("Todo description is empty")
    return false
  end
  
  -- Add current date to the title using configured format
  local current_date = os.date(M.config.date_format)
  local note_title = description .. " (" .. current_date .. ")"

  -- Get available directories
  local directories = get_notebook_directories()
  if #directories == 0 then
    print("No directories found in notebook")
    return false
  end
  
  -- Suggest directory based on category
  local suggested_dir = suggest_directory_for_category(todo.category)
  
  -- Add root option and sort with suggestion first
  table.insert(directories, 1, "") -- Root directory
  
  -- Move suggested directory to top if it exists
  for i, dir in ipairs(directories) do
    if dir == suggested_dir then
      table.remove(directories, i)
      table.insert(directories, 2, dir) -- After root
      break
    end
  end
  
  -- Create display options
  local display_options = {}
  for _, dir in ipairs(directories) do
    if dir == "" then
      table.insert(display_options, "📁 notebook/ (root)")
    elseif dir == suggested_dir then
      table.insert(display_options, "📁 " .. dir .. "/ (suggested for " .. todo.category .. ")")
    else
      table.insert(display_options, "📁 " .. dir .. "/")
    end
  end

  -- Present directory choice to user
  vim.ui.select(display_options, {
    prompt = "Select directory for note '" .. note_title .. "':",
  }, function(choice, idx)
    if not choice or not idx then
      print("Note creation cancelled")
      return
    end
    
    local selected_dir = directories[idx]
    local dir_arg = selected_dir == "" and "" or selected_dir
    
    -- Build zk command using working directory option
    local zk_cmd = string.format('zk new --working-dir "%s" --title "%s" --print-path', M.config.notebook_dir, note_title)
    if dir_arg ~= "" then
      zk_cmd = zk_cmd .. " " .. vim.fn.shellescape(dir_arg)
    end
    
    -- Execute zk command
    local handle = io.popen(zk_cmd .. " 2>&1")
    if not handle then
      print("Failed to execute zk command")
      return
    end
    
    local result = handle:read("*a")
    local exit_code = handle:close()
    
    if not exit_code then
      print("Error creating note: " .. result)
      return
    end

    -- Clean up the result - remove all newlines and extra whitespace
    result = result:gsub("[\r\n]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    local note_filename = result:match("([^/]+)$")
    print("✓ Created note: " .. (note_filename or result))
    
    -- Ask if user wants to open the note
    vim.ui.select({"Yes", "No"}, {
      prompt = "Open the note?",
    }, function(open_choice)
      if open_choice == "Yes" then
        -- Check if file exists before trying to open
        if vim.fn.filereadable(result) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(result))
        else
          print("Error: File does not exist at " .. result)
        end
      end
    end)
  end)

  return true
end

-- ========================================
-- TODO INTERACTION
-- ========================================

-- Toggle todo completion on current line
function M.toggle_todo_on_line()
  local line = vim.api.nvim_get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- Check if current line is a todo
  local todo = M.parse_todo_line(line)
  if not todo then
    print("Current line is not a todo item")
    return false
  end

  -- Normal toggle logic
  -- Toggle completion status
  todo.completed = not todo.completed

  -- Set appropriate date
  if todo.completed then
    todo.completion_date = get_current_date()
    todo.added_date = ""
  else
    todo.completion_date = ""
    if not todo.added_date or todo.added_date == "" then
      todo.added_date = get_current_date()
    end
  end

  -- Format the new line
  local new_line = M.format_todo_line(todo)

  -- Replace the current line
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

  -- Handle file movement if needed
  local current_file = vim.api.nvim_buf_get_name(0)
  local active_file_path = get_file_path(M.config.active_file)
  local completed_file_path = get_file_path(M.config.completed_file)

  if current_file == active_file_path and todo.completed then
    -- Remove from current buffer and add to completed file
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

    local completed_todos = M.get_completed_todos()
    table.insert(completed_todos, todo)

    local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
    M.write_todos_to_file(M.config.completed_file, completed_todos, completed_header)

    print("✓ Todo completed and moved to completed list")
  elseif current_file == completed_file_path and not todo.completed then
    -- Remove from current buffer and add to active file
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

    local active_todos = M.get_active_todos()
    table.insert(active_todos, todo)

    local active_header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
    M.write_todos_to_file(M.config.active_file, active_todos, active_header)

    print("↶ Todo uncompleted and moved back to active list")
  else
    local status = todo.completed and "completed" or "uncompleted"
    print("✓ Todo " .. status)
  end

  return true
end

-- ========================================
-- BUFFER FILTERING FUNCTIONS
-- ========================================

-- Buffer filtering functions for interactive todo views

-- Filter todos by due dates in scratch buffer
function M.filter_todos_by_due_dates()
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Collect todos with due dates
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if todo and todo.due_date and todo.due_date ~= "" then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end

      -- Add category icon (only if not already present)
      local icon = get_display_icon(todo)
      if icon ~= "" then
        display_text = display_text .. " " .. icon
      end

      -- Add due date with color indicator
      local due_indicator = is_past_due(todo.due_date) and " [OVERDUE: " or " [Due: "
      display_text = display_text .. due_indicator .. todo.due_date .. "]"

      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
        past_due = is_past_due(todo.due_date),
      })
    end
  end

  if #todos == 0 then
    print("No todos with due dates found")
    return
  end

  -- Create a new scratch buffer for filtered todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content
  local lines = {}
  table.insert(lines, "Due Date Todos (" .. #todos .. " found)")
  table.insert(lines, string.rep("=", #lines[1]))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file
  vim.b.filter_category = "due_dates"

  -- Set up keybindings (same as other filter functions)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file

    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        -- Close filter window first
        vim.cmd("close")

        -- Use vim.schedule to defer the navigation to avoid timing issues
        vim.schedule(function()
          -- Navigate to file and line
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      else
        print("Error: Invalid todo object or line_num")
      end
    else
      print("Error: Could not navigate to todo")
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      -- Jump to original file and toggle
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        -- Return to filter and refresh
        vim.defer_fn(function()
          M.filter_todos_by_due_dates()
        end, 100)
      end)
    else
      print("Error: Could not toggle todo")
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- Filter todos by category in scratch buffer
function M.filter_todos_by_category(category)
  if not category then
    print("Error: No category provided")
    return
  end

  -- Validate category
  if not vim.tbl_contains(M.config.categories, category) then
    print("Invalid category. Must be one of: " .. table.concat(M.config.categories, ", "))
    return
  end

  -- Check if we're in a todo file
  local current_file = vim.api.nvim_buf_get_name(0)
  local active_file_path = get_file_path(M.config.active_file)
  local completed_file_path = get_file_path(M.config.completed_file)

  if current_file ~= active_file_path and current_file ~= completed_file_path then
    print("Error: Must be in a todo file to filter")
    return
  end

  -- Get todos for the category
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Collect matching todos with their line numbers
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if todo and todo.category and todo.category:lower() == category:lower() then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end
      -- No category icon needed since header already shows the category
      if todo.due_date and todo.due_date ~= "" then
        display_text = display_text .. " [Due: " .. todo.due_date .. "]"
      end
      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
      })
    end
  end

  if #todos == 0 then
    print("No " .. category .. " todos found")
    return
  end

  -- Create a new scratch buffer for filtered todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content with category icon in header
  local lines = {}
  local category_icon = M.config.category_icons[category] or "📝"
  local header = category_icon .. " " .. category .. " Todos (" .. #todos .. " found)"
  table.insert(lines, header)
  table.insert(lines, string.rep("=", #header))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file
  vim.b.filter_category = category

  -- Set up keybindings
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file

    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        -- Close filter window first
        vim.cmd("close")

        -- Use vim.schedule to defer the navigation to avoid timing issues
        vim.schedule(function()
          -- Navigate to file and line
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      else
        print("Error: Invalid todo object or line_num")
      end
    else
      print("Error: Could not navigate to todo")
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    local category = vim.b.filter_category
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      -- Jump to original file and toggle
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        -- Return to filter and refresh
        vim.defer_fn(function()
          M.filter_todos_by_category(category)
        end, 100)
      end)
    else
      print("Error: Could not toggle todo")
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- Show all todos in scratch buffer
function M.show_all_todos()
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Get all todos
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if todo then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end
      -- Add category icon instead of text in parentheses (only if not already present)
      local icon = get_display_icon(todo)
      if icon ~= "" then
        display_text = display_text .. " " .. icon
      end
      if todo.due_date and todo.due_date ~= "" then
        display_text = display_text .. " [Due: " .. todo.due_date .. "]"
      end
      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
      })
    end
  end

  if #todos == 0 then
    print("No todos found")
    return
  end

  -- Create a new scratch buffer for all todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content
  local lines = {}
  table.insert(lines, "All Todos (" .. #todos .. " found)")
  table.insert(lines, string.rep("=", #lines[1]))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file

  -- Set up keybindings
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        -- Close filter window first
        vim.cmd("close")

        -- Use vim.schedule to defer the navigation
        vim.schedule(function()
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      else
        print("Error: Invalid todo object or line_num")
      end
    else
      print("Error: Could not navigate to todo")
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3 -- Adjust for header lines
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      -- Jump to original file and toggle
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        -- Return to filter and refresh
        vim.defer_fn(function()
          M.show_all_todos()
        end, 100)
      end)
    else
      print("Error: Could not toggle todo")
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- Filter today's todos in scratch buffer
function M.filter_todos_by_today()
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Collect todos due today
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if todo and todo.due_date and todo.due_date ~= "" and is_due_today(todo.due_date) then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end

      -- Add category icon
      local icon = get_display_icon(todo)
      if icon ~= "" then
        display_text = display_text .. " " .. icon
      end

      -- Add due date indicator
      display_text = display_text .. " [Due Today: " .. todo.due_date .. "]"

      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
      })
    end
  end

  if #todos == 0 then
    print("No todos due today found")
    return
  end

  -- Create a new scratch buffer for filtered todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content
  local lines = {}
  table.insert(lines, "Todos Due Today (" .. #todos .. " found)")
  table.insert(lines, string.rep("=", #lines[1]))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content and properties
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file
  vim.b.filter_category = "today"

  -- Set up keybindings (same pattern as other filter functions)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        vim.cmd("close")
        vim.schedule(function()
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      end
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        vim.defer_fn(function()
          M.filter_todos_by_today()
        end, 100)
      end)
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- Filter past due todos in scratch buffer
function M.filter_todos_by_past_due()
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Collect past due todos
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if todo and todo.due_date and todo.due_date ~= "" and is_past_due(todo.due_date) then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end

      -- Add category icon
      local icon = get_display_icon(todo)
      if icon ~= "" then
        display_text = display_text .. " " .. icon
      end

      -- Add overdue indicator
      display_text = display_text .. " [OVERDUE: " .. todo.due_date .. "]"

      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
      })
    end
  end

  if #todos == 0 then
    print("No past due todos found")
    return
  end

  -- Create a new scratch buffer for filtered todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content
  local lines = {}
  table.insert(lines, "Past Due Todos (" .. #todos .. " found)")
  table.insert(lines, string.rep("=", #lines[1]))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content and properties
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file
  vim.b.filter_category = "past_due"

  -- Set up keybindings (same pattern as other filter functions)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        vim.cmd("close")
        vim.schedule(function()
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      end
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        vim.defer_fn(function()
          M.filter_todos_by_past_due()
        end, 100)
      end)
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- Filter urgent todos in scratch buffer
function M.filter_todos_by_today_and_past_due()
  local source_file = vim.api.nvim_buf_get_name(0)
  local todos = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Collect todos due today or past due
  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local todo = M.parse_todo_line(line)

    if
        todo
        and todo.due_date
        and todo.due_date ~= ""
        and (is_due_today(todo.due_date) or is_past_due(todo.due_date))
    then
      local display_text = todo.description
      if todo.completed then
        display_text = display_text .. " ✓"
      end

      -- Add category icon
      local icon = get_display_icon(todo)
      if icon ~= "" then
        display_text = display_text .. " " .. icon
      end

      -- Add due date with appropriate indicator
      local due_indicator = is_past_due(todo.due_date) and " [OVERDUE: " or " [Due Today: "
      display_text = display_text .. due_indicator .. todo.due_date .. "]"

      if #todo.tags > 0 then
        display_text = display_text .. " #" .. table.concat(todo.tags, " #")
      end

      table.insert(todos, {
        text = display_text,
        line_num = line_num,
        completed = todo.completed,
        past_due = is_past_due(todo.due_date),
      })
    end
  end

  if #todos == 0 then
    print("No urgent todos found")
    return
  end

  -- Create a new scratch buffer for filtered todos
  local buf = vim.api.nvim_create_buf(false, true)

  -- Prepare buffer content
  local lines = {}
  table.insert(lines, "Today & Past Due Todos (" .. #todos .. " found)")
  table.insert(lines, string.rep("=", #lines[1]))
  table.insert(lines, "")

  for i, todo in ipairs(todos) do
    table.insert(lines, string.format("%d. %s", i, todo.text))
  end

  table.insert(lines, "")
  table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

  -- Set buffer content and properties
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

  -- Open in a split window
  vim.cmd("botright 15split")
  vim.api.nvim_win_set_buf(0, buf)

  -- Store todo data in buffer variable for navigation
  vim.b.filtered_todos = todos
  vim.b.source_file = source_file
  vim.b.filter_category = "today_and_past_due"

  -- Set up keybindings (same pattern as other filter functions)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      if todo and todo.line_num and type(todo.line_num) == "number" then
        vim.cmd("close")
        vim.schedule(function()
          vim.cmd.edit(vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        end)
      end
    end
  end, { buffer = buf, desc = "Jump to todo" })

  vim.keymap.set("n", "<Space>", function()
    local line = vim.fn.line(".") - 3
    local todos = vim.b.filtered_todos
    local file = vim.b.source_file
    if line >= 1 and line <= #todos and file then
      local todo = todos[line]
      vim.schedule(function()
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
        M.toggle_todo_on_line()
        vim.defer_fn(function()
          M.filter_todos_by_today_and_past_due()
        end, 100)
      end)
    end
  end, { buffer = buf, desc = "Toggle todo completion" })

  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, { buffer = buf, desc = "Close filter window" })
end

-- ========================================
-- DATE PICKER AND UTILITIES
-- ========================================

-- Interactive floating calendar date picker
function M.show_date_picker(callback)
  local current_date = os.date("*t")
  local selected_year = current_date.year
  local selected_month = current_date.month
  local selected_day = current_date.day
  local today = { year = current_date.year, month = current_date.month, day = current_date.day }

  -- Month names for display
  local month_names = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  }

  -- Function to get days in month
  local function days_in_month(month, year)
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)) then
      return 29 -- Leap year
    end
    return days[month]
  end

  -- Function to get first day of month (0=Sunday, 1=Monday, etc.)
  local function first_day_of_month(month, year)
    local first_date = os.time({ year = year, month = month, day = 1 })
    return tonumber(os.date("%w", first_date))
  end

  -- Create calendar buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "calendar")

  -- Function to render calendar
  local function render_calendar()
    local lines = {}

    -- Header with month and year
    local header = month_names[selected_month] .. " " .. selected_year
    table.insert(lines, " " .. string.rep(" ", math.floor((20 - #header) / 2)) .. header)
    table.insert(lines, " Su Mo Tu We Th Fr Sa")

    -- Get calendar data
    local max_days = days_in_month(selected_month, selected_year)
    local first_day = first_day_of_month(selected_month, selected_year)

    -- Build calendar grid
    local current_line = " "
    local day_count = 1

    -- Add spaces for days before first day of month
    for i = 1, first_day do
      current_line = current_line .. "   "
    end

    -- Add days of the month
    for day = 1, max_days do
      local day_str = string.format("%2d", day)

      -- Mark today with brackets
      if selected_year == today.year and selected_month == today.month and day == today.day then
        day_str = "[" .. string.format("%d", day) .. "]"
        if day < 10 then
          day_str = "[" .. day .. "]"
        end
      end

      -- Mark selected day with asterisk
      if day == selected_day then
        if day_str:match("%[") then
          day_str = day_str -- Already has brackets (today)
        else
          day_str = "*" .. string.format("%d", day) .. "*"
          if day < 10 then
            day_str = "*" .. day .. "*"
          end
        end
      end

      current_line = current_line .. day_str .. " "

      -- New line after Saturday (day 6)
      if (first_day + day - 1) % 7 == 6 then
        table.insert(lines, current_line)
        current_line = " "
      end
    end

    -- Add remaining line if needed
    if current_line ~= " " then
      table.insert(lines, current_line)
    end

    -- Add instructions
    table.insert(lines, "")
    table.insert(lines, " Navigation:")
    table.insert(lines, " • h/l: Previous/Next month")
    table.insert(lines, " • j/k: Previous/Next day")
    table.insert(lines, " • H/L: Previous/Next year")
    table.insert(lines, " • Enter: Select date")
    table.insert(lines, " • q/ESC: Cancel")
    table.insert(lines, "")
    table.insert(
      lines,
      " Selected: " .. string.format("%02d-%02d-%04d", selected_month, selected_day, selected_year)
    )

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end

  -- Open calendar in floating window
  local width = 28
  local height = 15
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    anchor = "NW",
    style = "minimal",
    border = "rounded",
    title = " 📅 Date Picker ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Initial render
  render_calendar()

  -- Set up navigation keymaps
  local function setup_keymaps()
    -- Navigate months
    vim.keymap.set("n", "h", function()
      selected_month = selected_month - 1
      if selected_month < 1 then
        selected_month = 12
        selected_year = selected_year - 1
      end
      -- Adjust day if it doesn't exist in new month
      local max_days = days_in_month(selected_month, selected_year)
      if selected_day > max_days then
        selected_day = max_days
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "l", function()
      selected_month = selected_month + 1
      if selected_month > 12 then
        selected_month = 1
        selected_year = selected_year + 1
      end
      -- Adjust day if it doesn't exist in new month
      local max_days = days_in_month(selected_month, selected_year)
      if selected_day > max_days then
        selected_day = max_days
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    -- Navigate days
    vim.keymap.set("n", "j", function()
      selected_day = selected_day + 1
      local max_days = days_in_month(selected_month, selected_year)
      if selected_day > max_days then
        selected_day = 1
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "k", function()
      selected_day = selected_day - 1
      if selected_day < 1 then
        selected_day = days_in_month(selected_month, selected_year)
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    -- Navigate years
    vim.keymap.set("n", "H", function()
      selected_year = selected_year - 1
      -- Adjust for leap year
      local max_days = days_in_month(selected_month, selected_year)
      if selected_day > max_days then
        selected_day = max_days
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "L", function()
      selected_year = selected_year + 1
      -- Adjust for leap year
      local max_days = days_in_month(selected_month, selected_year)
      if selected_day > max_days then
        selected_day = max_days
      end
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      render_calendar()
    end, { buffer = buf, silent = true })

    -- Selection and cancellation
    vim.keymap.set("n", "<CR>", function()
      local result = string.format("%02d-%02d-%04d", selected_month, selected_day, selected_year)
      vim.api.nvim_win_close(win, true)
      if callback then
        callback(result)
      end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "<ESC>", function()
      vim.api.nvim_win_close(win, true)
      if callback then
        callback(nil)
      end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(win, true)
      if callback then
        callback(nil)
      end
    end, { buffer = buf, silent = true })
  end

  setup_keymaps()
end

-- Get date input using calendar picker
function M.get_date_input(callback)
  M.show_date_picker(callback)
end

-- Update todo due date using calendar picker
function M.update_todo_date_on_line()
  local line = vim.api.nvim_get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- Check if current line is a todo
  local todo = M.parse_todo_line(line)
  if not todo then
    print("Current line is not a todo item")
    return false
  end

  -- Get new date using calendar picker (async)
  M.get_date_input(function(new_date)
    if not new_date then
      print("Date selection cancelled")
      return
    end

    -- Update the todo's due date
    todo.due_date = new_date

    -- Format the new line
    local new_line = M.format_todo_line(todo)

    -- Replace the current line
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

    -- Refresh syntax highlighting
    M.highlight_due_dates_with_colors()

    print("✓ Due date updated to: " .. new_date)
  end)

  return true
end

-- ========================================
-- CATEGORY MANAGEMENT
-- ========================================

-- Add new category with icon
function M.add_new_category(category_name, icon)
  if not category_name or category_name == "" then
    print("Error: Category name is required")
    return false
  end

  if not icon or icon == "" then
    print("Error: Category icon is required")
    return false
  end

  -- Check if category already exists
  if vim.tbl_contains(M.config.categories, category_name) then
    print("Error: Category '" .. category_name .. "' already exists")
    return false
  end

  -- Add to categories list
  table.insert(M.config.categories, category_name)

  -- Add icon mapping
  M.config.category_icons[category_name] = icon

  print("✓ Added new category: " .. category_name .. " " .. icon)
  print("Available categories: " .. table.concat(M.config.categories, ", "))
  return true
end

-- List all categories with icons
function M.list_categories()
  print("\nAvailable Categories:")
  print("====================")

  for _, category in ipairs(M.config.categories) do
    local icon = M.config.category_icons[category] or "📝"
    print(category .. ": " .. icon)
  end
  print("")
end

-- Update category icon
function M.update_category_icon(category_name, new_icon)
  if not category_name or category_name == "" then
    print("Error: Category name is required")
    return false
  end

  if not new_icon or new_icon == "" then
    print("Error: New icon is required")
    return false
  end

  if not vim.tbl_contains(M.config.categories, category_name) then
    print("Error: Category '" .. category_name .. "' does not exist")
    print("Available categories: " .. table.concat(M.config.categories, ", "))
    return false
  end

  local old_icon = M.config.category_icons[category_name] or "📝"
  M.config.category_icons[category_name] = new_icon

  print("✓ Updated " .. category_name .. " icon: " .. old_icon .. " → " .. new_icon)
  return true
end

-- ========================================
-- SYNTAX HIGHLIGHTING
-- ========================================

-- Setup syntax highlighting for todo files
function M.setup_todo_syntax()
  -- Only apply to markdown files in the todo directory
  local current_file = vim.api.nvim_buf_get_name(0)
  local todo_dir = M.config.todo_dir

  if not current_file:find(todo_dir, 1, true) then
    return
  end

  -- Clear existing syntax first
  vim.cmd("syntax clear")

  -- Keep markdown as base filetype
  vim.bo.filetype = "markdown"

  -- Define completed todos first (highest priority)
  vim.cmd([[syntax match TodoCompleted /^.*- \[x\].*$/]])
  vim.cmd([[highlight TodoCompleted ctermfg=8 guifg=#666666]])

  -- Define dates in parentheses - this will work on ALL lines including active todos
  vim.cmd([[syntax match TodoDateGray /(\d\{2\}-\d\{2\}-\d\{4\})/]])
  vim.cmd([[highlight TodoDateGray ctermfg=8 guifg=#666666]])

  -- Define hashtags (blue)
  vim.cmd([[syntax match TodoTag /#\w\+/]])
  vim.cmd([[highlight TodoTag ctermfg=blue guifg=#0080FF]])

  -- Define category icons BEFORE due dates to prevent conflicts
  vim.cmd([[syntax match TodoIcon /[💙💼👤📝]/]])
  vim.cmd([[highlight TodoIcon ctermfg=14 guifg=#00D7D7]])

  -- Force syntax refresh
  vim.cmd("syntax sync fromstart")

  -- Apply dynamic highlighting for due dates LAST (highest priority using matchadd)
  vim.defer_fn(function()
    M.highlight_due_dates_with_colors()
  end, 10)
end

-- Highlight due dates with colors
function M.highlight_due_dates_with_colors()
  -- Don't clear all matches, only clear our specific ones
  for _, match in pairs(vim.fn.getmatches()) do
    if match.group == "TodoDuePast" or match.group == "TodoDueFuture" or match.group == "TodoDueToday" then
      vim.fn.matchdelete(match.id)
    end
  end

  -- Define highlight groups with strong colors that override everything
  vim.cmd("highlight! TodoDueFuture ctermfg=8 cterm=NONE guifg=#666666 gui=NONE")   -- Light gray like completed todos, non-bold
  vim.cmd("highlight! TodoDuePast ctermfg=196 cterm=NONE guifg=#DC143C gui=NONE")   -- Crimson Red, non-bold
  vim.cmd("highlight! TodoDueToday ctermfg=green cterm=NONE guifg=#228B22 gui=NONE") -- Forest Green, non-bold

  local total_lines = vim.api.nvim_buf_line_count(0)

  for line_num = 1, total_lines do
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    if line then
      -- Skip completed todos - no need to highlight their dates
      local todo = M.parse_todo_line(line)
      if todo and todo.completed then
        goto continue
      end

      -- Look for due dates in the line
      local due_date = line:match("%[Due:%s*([^%]]+)%]")
      if due_date then
        -- Clean up any extra spaces
        due_date = due_date:match("^%s*(.-)%s*$")

        -- Create pattern for the entire due date block (don't escape hyphens)
        local pattern = "\\[Due:\\s*" .. due_date .. "\\]"

        -- Use matchadd with maximum priority to override any syntax highlighting
        -- Three-way logic: past due (red) > today (green) > future (yellow)
        if is_past_due(due_date) then
          vim.fn.matchadd("TodoDuePast", pattern, 1000) -- Maximum priority
        elseif is_due_today(due_date) then
          vim.fn.matchadd("TodoDueToday", pattern, 1000) -- Maximum priority
        else
          vim.fn.matchadd("TodoDueFuture", pattern, 1000) -- Maximum priority
        end
      end

      ::continue::
    end
  end
end

-- Legacy function
function M.highlight_past_due_dates()
  M.highlight_due_dates_with_colors()
end

return M
