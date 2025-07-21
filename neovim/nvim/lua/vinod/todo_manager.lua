-- Vinod's Todo Manager for Neovim with zk integration
-- Manages todos with categories, tags, and due dates in markdown format
-- Compatible with zk note-taking system

local M = {}

-- Configuration for the todo system
-- All file paths and categories are defined here
-- Date format follows mm-dd-yyyy as requested
M.config = {
	todo_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo",
	active_file = "active-todos.md",
	completed_file = "completed-todos.md",
	categories = { "Medicine", "OMS", "Personal" },
	date_format = "%m-%d-%Y", -- mm-dd-YYYY format as requested
	-- Category icons for clean display
	category_icons = {
		Medicine = "💙",
		OMS = "💼",
		Personal = "👤",
	},
}

-- Get current date in the configured format (mm-dd-yyyy)
-- Used for automatically setting added_date and completion_date
-- Returns: formatted date string
local function get_current_date()
	return os.date(M.config.date_format)
end

-- Check if a date string is past due
-- Compares date in mm-dd-yyyy format with current date
-- Returns: boolean (true if past due)
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
	local due_time = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 23,
		min = 59,
		sec = 59,
	})

	local current_time = os.time()
	return current_time > due_time
end

-- Construct full file path by combining todo directory with filename
-- Ensures consistent path handling across all file operations
-- Returns: absolute file path string
local function get_file_path(filename)
	return M.config.todo_dir .. "/" .. filename
end

-- Parse a todo line into components
-- Handles both old pipe format and new clean format with icons
-- Old format: - [ ] Description | Category: Medicine | Tags: #tag1 | Due: 07-20-2025
-- New format: - [ ] [icon] Description [Due: date] #tag1 (date)
-- Returns: todo table with all parsed fields or nil if not a valid todo line
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

-- Format a todo object back into a clean markdown line with icons
-- Creates clean format: "- [ ] [icon] Description [Due: date] #tags (date)"
-- Icon appears right after checkbox for better visual organization
-- Returns: formatted markdown string
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

	-- Add added date for active todos (subtle, no "Added:" label)
	if todo.added_date and todo.added_date ~= "" and not todo.completed then
		line = line .. " (" .. todo.added_date .. ")"
	end

	-- Add completion date for completed todos (subtle, no "Completed:" label)
	if todo.completion_date and todo.completion_date ~= "" then
		line = line .. " (" .. todo.completion_date .. ")"
	end

	return line
end

-- Read and parse all todos from a markdown file
-- Opens the specified file, reads line by line, and parses each todo
-- Skips non-todo lines (headers, empty lines, etc.)
-- Returns: array of todo objects
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

-- Write todos to a markdown file with proper formatting
-- Creates/overwrites the file with a header and all todos
-- Each todo is formatted using format_todo_line()
-- Returns: boolean success status
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

-- Get all active (non-completed) todos from the active file
-- Reads from active-todos.md and filters out any completed todos
-- This ensures we only return truly active todos even if some completed ones
-- accidentally remain in the active file
-- Returns: array of active todo objects
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

-- Get all completed todos from the completed file
-- Simply reads and returns all todos from completed-todos.md
-- Returns: array of completed todo objects
function M.get_completed_todos()
	return M.read_todos_from_file(M.config.completed_file)
end

-- Add a new todo to the active todos file
-- Creates a new todo with the provided details and current date as added_date
-- Validates category against allowed categories
-- Defaults to "Personal" category if none provided
-- Automatically refreshes the active todos file if it's currently open
-- Returns: boolean success status
function M.add_todo(description, category, tags, due_date)
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

-- Refresh the active todos file if it's currently open in any buffer
-- Automatically reloads the file content and reapplies syntax highlighting
-- Called after adding new todos to keep the display up to date
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
						vim.cmd("e!") -- Force reload from disk
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

-- Complete a todo by moving it from active to completed file
-- Marks the todo as completed, adds completion date, and moves it
-- Updates both active and completed files atomically
-- Returns: boolean success status
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

-- Permanently delete a todo from the active file
-- Removes the todo completely (does not move to completed)
-- Use complete_todo() instead if you want to preserve the todo
-- Returns: boolean success status
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

-- Clean up any completed todos that may be in the active file
-- Sometimes todos get marked complete but not moved properly
-- This function finds completed todos in active file and moves them
-- Also adds missing dates to todos that lack them
-- Called during initialization to maintain file integrity
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

-- Initialize the todo system by creating necessary files and directories
-- Creates the todo directory if it doesn't exist
-- Creates empty active and completed files with proper headers
-- Runs cleanup to ensure file integrity
-- Called automatically when the module loads
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

-- Display todos in a formatted, human-readable way with clean icon-based categories
-- Shows numbered list with status, description, category icon, tags, and dates
-- Used by list commands to show todos in the command line
-- Returns: nothing (prints to stdout)
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

-- Filter an array of todos by category (case-insensitive)
-- Used for command-line filtering, not buffer filtering
-- Returns: new array containing only matching todos
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

-- Filter todos that have due dates
-- Returns: new array containing only todos with due dates
function M.filter_todos_with_due_dates(todos)
	local filtered = {}
	for _, todo in ipairs(todos) do
		if todo.due_date and todo.due_date ~= "" then
			table.insert(filtered, todo)
		end
	end
	return filtered
end

-- Filter todos that are past due
-- Returns: new array containing only past due todos
function M.filter_past_due_todos(todos)
	local filtered = {}
	for _, todo in ipairs(todos) do
		if todo.due_date and todo.due_date ~= "" and is_past_due(todo.due_date) then
			table.insert(filtered, todo)
		end
	end
	return filtered
end

-- List active todos with optional category filtering
-- Displays todos in formatted output to command line
-- If category provided, shows only todos from that category
function M.list_active_todos(category)
	local todos = M.get_active_todos()

	if category then
		todos = M.filter_todos_by_category(todos, category)
		M.display_todos(todos, "Active Todos - " .. category .. " Category")
	else
		M.display_todos(todos, "Active Todos")
	end
end

-- List completed todos with optional category filtering
-- Displays todos in formatted output to command line
-- If category provided, shows only todos from that category
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
-- Shows all active todos that have due dates set
function M.list_due_todos()
	local todos = M.get_active_todos()
	local due_todos = M.filter_todos_with_due_dates(todos)
	M.display_todos(due_todos, "Todos with Due Dates")
end

-- List past due todos
-- Shows all active todos that are past their due date
function M.list_past_due_todos()
	local todos = M.get_active_todos()
	local past_due_todos = M.filter_past_due_todos(todos)
	M.display_todos(past_due_todos, "Past Due Todos")
end

-- Show comprehensive view of a specific category
-- Displays both active and completed todos for the given category
-- Includes summary statistics
-- Used by category-specific view commands
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

-- Toggle completion status of todo on current cursor line
-- Works in both normal buffers and filtered views
-- Handles moving todos between active/completed files when appropriate
-- Updates dates automatically (added/completed)
-- Returns: boolean success status
function M.toggle_todo_on_line()
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	-- Check if current line is a todo
	local todo = M.parse_todo_line(line)
	if not todo then
		print("Current line is not a todo item")
		return false
	end

	-- If we're in a filtered view, we need to handle this differently
	if vim.b.todo_filter and vim.b.todo_filter.is_filtered then
		-- First restore original content to make the change
		local current_filter = vim.b.todo_filter.category
		M.restore_original_content()

		-- Find the todo in the original content and update it
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local found = false

		for i, original_line in ipairs(lines) do
			local original_todo = M.parse_todo_line(original_line)
			if
				original_todo
				and original_todo.description == todo.description
				and original_todo.category == todo.category
			then
				-- Toggle completion status
				original_todo.completed = not original_todo.completed

				-- Set appropriate date
				if original_todo.completed then
					original_todo.completion_date = get_current_date()
					original_todo.added_date = ""
				else
					original_todo.completion_date = ""
					if not original_todo.added_date or original_todo.added_date == "" then
						original_todo.added_date = get_current_date()
					end
				end

				-- Update the line
				local new_line = M.format_todo_line(original_todo)
				vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
				found = true
				break
			end
		end

		if found then
			-- Re-apply the filter
			M.filter_todos_by_category_in_buffer(current_filter)
			local status = not todo.completed and "completed" or "uncompleted"
			print("✓ Todo " .. status .. " (filter maintained)")
		else
			print("✗ Could not find todo to update")
		end

		return found
	end

	-- Normal toggle logic for non-filtered view
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
-- BUFFER FILTERING FUNCTIONALITY (DISABLED)
-- ========================================
-- The following functions implement in-buffer filtering of todos
-- This feature was disabled due to technical issues:
-- - Buffer modification approach caused users to get stuck in filtered states
-- - Persistence mechanism prevented returning to full view
-- - Treesitter highlighting errors and concealing issues
-- These functions are kept for future reference and potential fixes

-- Get line numbers of todos matching a specific category
-- Used by filtering system to identify which lines to show/hide
-- Returns: array of line numbers (1-indexed)
function M.get_todo_line_numbers_by_category(category)
	local line_numbers = {}
	local total_lines = vim.api.nvim_buf_line_count(0)

	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		local todo = M.parse_todo_line(line)

		if todo and todo.category and todo.category:lower() == category:lower() then
			table.insert(line_numbers, line_num)
		end
	end

	return line_numbers
end

-- Get line numbers of all todos in current buffer
-- Used for buffer analysis and filtering operations
-- Returns: array of line numbers (1-indexed)
function M.get_all_todo_line_numbers()
	local line_numbers = {}
	local total_lines = vim.api.nvim_buf_line_count(0)

	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		local todo = M.parse_todo_line(line)

		if todo then
			table.insert(line_numbers, line_num)
		end
	end

	return line_numbers
end

-- Count todos by category in the current buffer
-- Analyzes buffer content and provides category breakdown
-- Returns: counts table and total count
function M.count_todos_in_buffer()
	local counts = { Medicine = 0, OMS = 0, Personal = 0 }
	local total_lines = vim.api.nvim_buf_line_count(0)

	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		local todo = M.parse_todo_line(line)

		if todo and todo.category and counts[todo.category] then
			counts[todo.category] = counts[todo.category] + 1
		end
	end

	local total = counts.Medicine + counts.OMS + counts.Personal
	return counts, total
end

-- Apply category filter using folding approach (DISABLED)
-- This was the most promising filtering approach but still had issues
-- Uses vim folding to hide non-matching todos instead of buffer modification
-- More reliable than concealing/buffer changes but still has persistence problems
-- CURRENTLY DISABLED - keybindings show "temporarily disabled" message
function M.filter_todos_by_category_in_buffer(category)
	if not category then
		print("Error: No category provided to filter function")
		return
	end

	-- Clear any existing filter first
	M.clear_todo_filter()

	if category == "All" then
		M.clear_todo_filter()
		print("✓ Showing all todos")
		return
	end

	-- Validate category
	if not vim.tbl_contains(M.config.categories, category) then
		print("Invalid category. Must be one of: " .. table.concat(M.config.categories, ", "))
		return
	end

	-- Count todos for display
	local total_lines = vim.api.nvim_buf_line_count(0)
	local total_todos = 0
	local matching_todos = 0
	local lines_to_fold = {}

	-- Find todos that don't match the filter
	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		local todo = M.parse_todo_line(line)

		if todo then
			total_todos = total_todos + 1
			if todo.category and todo.category:lower() == category:lower() then
				matching_todos = matching_todos + 1
			else
				-- This todo doesn't match - mark for folding
				table.insert(lines_to_fold, line_num)
			end
		end
	end

	if matching_todos == 0 then
		print("No " .. category .. " todos found")
		return
	end

	-- Set up manual folding
	vim.wo.foldmethod = "manual"
	vim.cmd("normal! zE") -- Clear existing folds

	-- Fold non-matching todos
	for _, line_num in ipairs(lines_to_fold) do
		vim.cmd(line_num .. "fold")
	end

	-- Set fold level to hide folded content
	vim.wo.foldlevel = 0

	-- Store filter state
	vim.b.todo_filter = {
		category = category,
		visible_count = matching_todos,
		total_count = total_todos,
		is_filtered = true,
		folded_lines = lines_to_fold,
	}

	M.update_statusline()
	print("✓ Filtered to " .. category .. " todos (" .. matching_todos .. " of " .. total_todos .. ")")
end

-- Clear all todo filters and restore normal view
-- Removes all folds and resets buffer to normal state
-- Part of the disabled filtering system
function M.clear_todo_filter()
	-- Clear all folds
	vim.cmd("normal! zR") -- Open all folds
	vim.cmd("normal! zE") -- Delete all folds

	-- Reset fold settings
	vim.wo.foldmethod = "manual"
	vim.wo.foldlevel = 99

	-- Clear filter state
	vim.b.todo_filter = nil

	M.update_statusline()
end

-- Update statusline to show current filter status
-- Displays which category is filtered and count information
-- Part of the disabled filtering system
function M.update_statusline()
	local filter = vim.b.todo_filter
	if filter then
		vim.b.todo_statusline =
			string.format("Filtered: %s (%d of %d todos)", filter.category, filter.visible_count, filter.total_count)
	else
		vim.b.todo_statusline = nil
	end
end

-- Restore filter state when opening todo files
-- Attempts to restore previously applied filters
-- Part of the disabled filtering system
-- Currently only updates statusline
function M.restore_filter_on_open()
	-- Check if this is a todo file
	local current_file = vim.api.nvim_buf_get_name(0)
	local active_file_path = get_file_path(M.config.active_file)
	local completed_file_path = get_file_path(M.config.completed_file)

	if current_file ~= active_file_path and current_file ~= completed_file_path then
		return
	end

	-- Check if there's a saved filter preference (could be stored in a config file)
	-- For now, we'll just ensure statusline is updated
	vim.defer_fn(function()
		M.update_statusline()
	end, 100)
end

-- Check if a description already contains a category icon
-- Prevents duplicate icon display in filtered views
-- Returns: boolean true if description already has an icon
local function description_has_icon(description)
	if not description or description == "" then
		return false
	end

	-- Check if description contains any of the known category icons
	for _, icon in pairs(M.config.category_icons) do
		if description:find(icon, 1, true) then
			return true
		end
	end

	-- Also check for the fallback icon
	if description:find("📝", 1, true) then
		return true
	end

	return false
end

-- Get display icon for todo, avoiding duplicates
-- Returns the appropriate icon only if description doesn't already contain one
-- Returns: string icon or empty string if description already has icon
local function get_display_icon(todo)
	if not todo.category or todo.category == "" then
		return description_has_icon(todo.description) and "" or "📝"
	end

	if description_has_icon(todo.description) then
		return "" -- Don't add icon if description already has one
	end

	return M.config.category_icons[todo.category] or "📝"
end

-- ========================================
-- CUSTOM BUFFER FILTERING SYSTEM
-- ========================================
-- This approach uses a custom scratch buffer to show filtered todos
-- Provides clean display without quickfix formatting clutter

-- Filter todos by due dates using a custom scratch buffer
-- Opens a clean window showing only todos with due dates
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

-- Filter todos by category using a custom scratch buffer
-- Opens a clean window showing only todos from the specified category
-- Users can navigate to any todo by pressing Enter
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
			-- Add category icon (only if not already present)
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
		print("No " .. category .. " todos found")
		return
	end

	-- Create a new scratch buffer for filtered todos
	local buf = vim.api.nvim_create_buf(false, true)

	-- Prepare buffer content
	local lines = {}
	table.insert(lines, category .. " Todos (" .. #todos .. " found)")
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

	print("✓ Filtered to " .. category .. " todos (" .. #todos .. " found)")
	print("Use Enter to jump to todo, Space to toggle completion, q to close")
end

-- Show all todos in a custom buffer (no filtering)
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

	print("✓ Showing all todos (" .. #todos .. " found)")
	print("Use Enter to jump to todo, Space to toggle completion, q to close")
end

-- Add a new category with custom icon
-- Adds the category to both the categories list and icon mapping
-- Validates that category doesn't already exist
-- Returns: boolean success status
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

-- List all available categories with their icons
-- Shows current category configuration for user reference
function M.list_categories()
	print("\nAvailable Categories:")
	print("====================")

	for _, category in ipairs(M.config.categories) do
		local icon = M.config.category_icons[category] or "📝"
		print(category .. ": " .. icon)
	end
	print("")
end

-- Update icon for an existing category
-- Allows changing the visual representation of a category
-- Returns: boolean success status
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

-- Setup syntax highlighting for todo files
-- Makes dates appear grayed out and icons more prominent
-- Called automatically when opening todo files
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

-- Highlight due dates with appropriate colors using matchadd (higher priority)
function M.highlight_due_dates_with_colors()
	-- Don't clear all matches, only clear our specific ones
	for _, match in pairs(vim.fn.getmatches()) do
		if match.group == "TodoDuePast" or match.group == "TodoDueFuture" then
			vim.fn.matchdelete(match.id)
		end
	end

	-- Define highlight groups with strong colors that override everything
	vim.cmd("highlight! TodoDueFuture ctermfg=yellow cterm=bold guifg=#B8860B gui=bold") -- Darker Yellow (DarkGoldenrod)
	vim.cmd("highlight! TodoDuePast ctermfg=196 cterm=bold guifg=#DC143C gui=bold") -- Crimson Red

	local total_lines = vim.api.nvim_buf_line_count(0)

	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		if line then
			-- Look for due dates in the line
			local due_date = line:match("%[Due:%s*([^%]]+)%]")
			if due_date then
				-- Clean up any extra spaces
				due_date = due_date:match("^%s*(.-)%s*$")

				-- Create pattern for the entire due date block (don't escape hyphens)
				local pattern = "\\[Due:\\s*" .. due_date .. "\\]"

				-- Use matchadd with maximum priority to override any syntax highlighting
				if is_past_due(due_date) then
					vim.fn.matchadd("TodoDuePast", pattern, 1000) -- Maximum priority
				else
					vim.fn.matchadd("TodoDueFuture", pattern, 1000) -- Maximum priority
				end
			end
		end
	end
end

-- Legacy function for compatibility
function M.highlight_past_due_dates()
	M.highlight_due_dates_with_colors()
end

-- Clean HTML span elements from todo files and migrate to clean format
-- Removes HTML span elements and converts to simple parentheses format
-- Also migrates old pipe format to new clean format
-- Returns: boolean success status
function M.cleanup_html_and_migrate()
	print("🔄 Starting cleanup of HTML elements and migration to clean format...")

	local function clean_html_from_line(line)
		-- Remove HTML span elements and extract the date
		local cleaned = line:gsub("<span[^>]*>([^<]*)</span>", "(%1)")
		return cleaned
	end

	-- Clean active todos
	local active_file_path = get_file_path(M.config.active_file)
	local active_file = io.open(active_file_path, "r")
	local active_lines = {}
	local active_cleaned = 0

	if active_file then
		for line in active_file:lines() do
			if line:find("<span") then
				local cleaned_line = clean_html_from_line(line)
				table.insert(active_lines, cleaned_line)
				active_cleaned = active_cleaned + 1
			else
				table.insert(active_lines, line)
			end
		end
		active_file:close()

		-- Write cleaned content back
		if active_cleaned > 0 then
			local file = io.open(active_file_path, "w")
			for _, line in ipairs(active_lines) do
				file:write(line .. "\n")
			end
			file:close()
		end
	end

	-- Clean completed todos
	local completed_file_path = get_file_path(M.config.completed_file)
	local completed_file = io.open(completed_file_path, "r")
	local completed_lines = {}
	local completed_cleaned = 0

	if completed_file then
		for line in completed_file:lines() do
			if line:find("<span") then
				local cleaned_line = clean_html_from_line(line)
				table.insert(completed_lines, cleaned_line)
				completed_cleaned = completed_cleaned + 1
			else
				table.insert(completed_lines, line)
			end
		end
		completed_file:close()

		-- Write cleaned content back
		if completed_cleaned > 0 then
			local file = io.open(completed_file_path, "w")
			for _, line in ipairs(completed_lines) do
				file:write(line .. "\n")
			end
			file:close()
		end
	end

	print("✓ Cleaned " .. active_cleaned .. " HTML elements from active todos")
	print("✓ Cleaned " .. completed_cleaned .. " HTML elements from completed todos")

	-- Now run the regular migration
	M.migrate_todos_to_new_format()

	return true
end

-- Migrate all todos from old pipe format to new clean format
-- Converts existing todos in both active and completed files
-- Preserves all data while updating to clean display format
-- Returns: boolean success status
function M.migrate_todos_to_new_format()
	print("🔄 Starting migration to new clean format...")

	-- Migrate active todos
	local active_todos = M.read_todos_from_file(M.config.active_file)
	local active_migrated = 0

	for i, todo in ipairs(active_todos) do
		if todo.raw_line:find("|") then
			active_migrated = active_migrated + 1
		end
	end

	if active_migrated > 0 then
		local active_header = "# Active Todos\n\nManaged by Vinod's Todo Manager"
		M.write_todos_to_file(M.config.active_file, active_todos, active_header)
		print("✓ Migrated " .. active_migrated .. " active todos")
	else
		print("✓ Active todos already in new format")
	end

	-- Migrate completed todos
	local completed_todos = M.read_todos_from_file(M.config.completed_file)
	local completed_migrated = 0

	for i, todo in ipairs(completed_todos) do
		if todo.raw_line:find("|") then
			completed_migrated = completed_migrated + 1
		end
	end

	if completed_migrated > 0 then
		local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
		M.write_todos_to_file(M.config.completed_file, completed_todos, completed_header)
		print("✓ Migrated " .. completed_migrated .. " completed todos")
	else
		print("✓ Completed todos already in new format")
	end

	local total_migrated = active_migrated + completed_migrated
	if total_migrated > 0 then
		print("🎉 Migration complete! Converted " .. total_migrated .. " todos to new clean format")
		print("📝 Your todos now use icons and grayed out dates")
	else
		print("✓ All todos are already in the new format")
	end

	return true
end

return M
