-- TEMPORARY TODO MANAGER FOR TESTING REFACTORED FUNCTIONS
-- This file contains just the working refactored buffer filtering functions
-- for testing purposes while we clean up the main file.

local M = {}

-- ========================================
-- CONFIGURATION
-- ========================================

M.config = {
	active_file = "active-todos.md",
	completed_file = "completed-todos.md",
	todo_directory = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo",
	categories = { "Medicine", "OMS", "Personal" },
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
	return os.date("%m-%d-%Y")
end

-- Check if a date is past due
function is_past_due(date_str)
	if not date_str or date_str == "" then
		return false
	end
	
	local current_date = get_current_date()
	local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
	local cur_month, cur_day, cur_year = current_date:match("(%d+)-(%d+)-(%d+)")
	
	if not month or not cur_month then
		return false
	end
	
	local date_time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
	local current_time = os.time({year = tonumber(cur_year), month = tonumber(cur_month), day = tonumber(cur_day)})
	
	return date_time < current_time
end

-- Check if a date is due today
function is_due_today(date_str)
	if not date_str or date_str == "" then
		return false
	end
	return date_str == get_current_date()
end

-- Get display icon for a todo based on category
function get_display_icon(todo)
	if not todo or not todo.category then
		return "📝"
	end
	return M.config.category_icons[todo.category] or "📝"
end

-- Get full file path for todo files
function get_file_path(filename)
	return M.config.todo_directory .. "/" .. filename
end

-- ========================================
-- TODO PARSING
-- ========================================

-- Parse a todo line into components
function M.parse_todo_line(line)
	if not line or line == "" or not line:match("^%s*%-") then
		return nil
	end

	local todo = {
		completed = false,
		description = "",
		category = "Personal",
		tags = {},
		due_date = "",
		show_date = "",
		added_date = "",
		completion_date = "",
		raw_line = line,
	}

	-- Check if completed
	if line:match("%[x%]") or line:match("%[X%]") then
		todo.completed = true
	end

	-- Parse clean format: - [ ] 💊 Take medicine [Show: date] [Due: date] #tag (added_date)
	local desc_part = line:match("^%s*%- %[.%] (.+)$")
	if desc_part then
		-- Extract show date
		local show_match = desc_part:match("%[Show: ([%d%-]+)%]")
		if show_match then
			todo.show_date = show_match
			desc_part = desc_part:gsub("%s*%[Show: [%d%-]+%]", "")
		end

		-- Extract due date
		local due_match = desc_part:match("%[Due: ([%d%-]+)%]")
		if due_match then
			todo.due_date = due_match
			desc_part = desc_part:gsub("%s*%[Due: [%d%-]+%]", "")
		end

		-- Extract added date (in parentheses at end)
		local added_match = desc_part:match("%(([%d%-]+)%)%s*$")
		if added_match then
			todo.added_date = added_match
			desc_part = desc_part:gsub("%s*%(([%d%-]+)%)%s*$", "")
		end

		-- Extract tags
		for tag in desc_part:gmatch("#(%w+)") do
			table.insert(todo.tags, tag)
		end
		desc_part = desc_part:gsub("%s*#%w+", "")

		-- Extract category from icon
		for category, icon in pairs(M.config.category_icons) do
			if desc_part:find(icon, 1, true) then
				todo.category = category
				desc_part = desc_part:gsub(icon, ""):gsub("^%s+", ""):gsub("%s+$", "")
				break
			end
		end

		todo.description = desc_part:gsub("^%s+", ""):gsub("%s+$", "")
	end

	return todo
end

-- ========================================
-- REFACTORED BUFFER FILTERING UTILITIES
-- ========================================

-- Collect todos with a filter function
local function collect_todos_with_filter(filter_function)
	local todos = {}
	local total_lines = vim.api.nvim_buf_line_count(0)

	for line_num = 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
		local todo = M.parse_todo_line(line)

		if todo and filter_function(todo) then
			local display_text = todo.description
			if todo.completed then
				display_text = display_text .. " ✓"
			end

			-- Add category icon
			local icon = get_display_icon(todo)
			if icon ~= "" then
				display_text = display_text .. " " .. icon
			end

			-- Add due date with color indicator if present
			if todo.due_date and todo.due_date ~= "" then
				local due_indicator = is_past_due(todo.due_date) and " [OVERDUE: " or " [Due: "
				display_text = display_text .. due_indicator .. todo.due_date .. "]"
			end

			-- Add show date if present and different from due date
			if todo.show_date and todo.show_date ~= "" and todo.show_date ~= todo.due_date then
				display_text = display_text .. " [Show: " .. todo.show_date .. "]"
			end

			-- Add tags
			if #todo.tags > 0 then
				display_text = display_text .. " #" .. table.concat(todo.tags, " #")
			end

			table.insert(todos, {
				text = display_text,
				line_num = line_num,
				completed = todo.completed,
				past_due = todo.due_date and is_past_due(todo.due_date) or false,
			})
		end
	end

	return todos
end

-- Create a filter buffer with todos and setup
local function create_filter_buffer(todos, title, filter_type, source_file)
	if #todos == 0 then
		print("No todos found for " .. title:lower())
		return nil
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {}
	
	table.insert(lines, title .. " (" .. #todos .. " found)")
	table.insert(lines, string.rep("=", #lines[1]))
	table.insert(lines, "")

	for i, todo in ipairs(todos) do
		table.insert(lines, string.format("%d. %s", i, todo.text))
	end

	table.insert(lines, "")
	table.insert(lines, "Press Enter to jump to todo, Space to toggle completion, q to close")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "todofilter")

	vim.cmd("botright 15split")
	vim.api.nvim_win_set_buf(0, buf)

	vim.b.filtered_todos = todos
	vim.b.source_file = source_file
	vim.b.filter_category = filter_type

	return buf
end

-- Setup common keymaps for filter buffers
local function setup_filter_keymaps(buf, todos)
	-- Enter - Jump to todo
	vim.keymap.set("n", "<CR>", function()
		local line = vim.fn.line(".") - 3
		local filtered_todos = vim.b.filtered_todos
		local file = vim.b.source_file

		if line >= 1 and line <= #filtered_todos and file then
			local todo = filtered_todos[line]
			if todo and todo.line_num and type(todo.line_num) == "number" then
				vim.cmd("close")
				vim.schedule(function()
					vim.cmd.edit({ vim.fn.fnameescape(file), bang = true })
					vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
				end)
			else
				print("Error: Invalid todo object or line_num")
			end
		else
			print("Error: Could not navigate to todo")
		end
	end, { buffer = buf, desc = "Jump to todo" })

	-- Space - Toggle completion (simplified for temp version)
	vim.keymap.set("n", "<Space>", function()
		local line = vim.fn.line(".") - 3
		local filtered_todos = vim.b.filtered_todos
		local file = vim.b.source_file

		if line >= 1 and line <= #filtered_todos and file then
			local todo = filtered_todos[line]
			if todo and todo.line_num and type(todo.line_num) == "number" then
				vim.cmd("close")
				vim.schedule(function()
					vim.cmd.edit({ vim.fn.fnameescape(file), bang = true })
					vim.api.nvim_win_set_cursor(0, { todo.line_num, 0 })
					print("Toggle functionality - use 'tt' in the todo file")
				end)
			else
				print("Error: Could not toggle todo")
			end
		else
			print("Error: Could not toggle todo")
		end
	end, { buffer = buf, desc = "Toggle todo completion" })

	-- q - Close window
	vim.keymap.set("n", "q", function()
		vim.cmd("close")
	end, { buffer = buf, desc = "Close filter window" })
end

-- ========================================
-- REFACTORED BUFFER FILTERING FUNCTIONS
-- ========================================

-- Filter todos by due dates in scratch buffer
function M.filter_buffer_by_due_dates()
	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return todo.due_date and todo.due_date ~= ""
	end)
	
	local buf = create_filter_buffer(todos, "Due Date Todos", "due_dates", source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- Filter todos by category in scratch buffer
function M.filter_buffer_by_category(category)
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

	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return todo.category == category
	end)
	
	local buf = create_filter_buffer(todos, category .. " Todos", "category_" .. category:lower(), source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- Show all todos in scratch buffer
function M.show_all_todos()
	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return true  -- Show all todos
	end)
	
	local buf = create_filter_buffer(todos, "All Todos", "all", source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- Filter today's todos in scratch buffer
function M.filter_buffer_by_today()
	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return todo.due_date and todo.due_date ~= "" and is_due_today(todo.due_date)
	end)
	
	local buf = create_filter_buffer(todos, "Today's Todos", "today", source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- Filter past due todos in scratch buffer
function M.filter_buffer_by_past_due()
	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return todo.due_date and todo.due_date ~= "" and is_past_due(todo.due_date)
	end)
	
	local buf = create_filter_buffer(todos, "Past Due Todos", "past_due", source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- Filter urgent todos (today + past due) in scratch buffer
function M.filter_buffer_by_today_and_past_due()
	local source_file = vim.api.nvim_buf_get_name(0)
	
	local todos = collect_todos_with_filter(function(todo)
		return todo.due_date and todo.due_date ~= "" and (is_due_today(todo.due_date) or is_past_due(todo.due_date))
	end)
	
	local buf = create_filter_buffer(todos, "Urgent Todos (Today + Past Due)", "urgent", source_file)
	if buf then
		setup_filter_keymaps(buf, todos)
	end
end

-- ========================================
-- DATE PICKER CONSOLIDATION UTILITIES (PHASE 2)
-- ========================================

-- Consolidated date picker utility function
-- Handles the most common date picker usage patterns
function M.get_date_with_action(options)
	-- Default options
	local opts = vim.tbl_extend("force", {
		on_success = nil,              -- Required: function(picked_date)
		on_cancel = nil,               -- Optional: function()
		fallback_date = "none",        -- "today", "none", or specific date string
		cancel_message = nil,          -- Optional: custom cancel message
		success_message = nil,         -- Optional: success message template
		auto_fallback = false,         -- Auto-apply fallback if cancelled
	}, options or {})

	-- Validate required callback
	if not opts.on_success or type(opts.on_success) ~= "function" then
		error("get_date_with_action: on_success callback is required")
		return
	end

	-- Call the original date picker
	M.get_date_input(function(picked_date)
		if picked_date then
			-- Success path
			if opts.success_message then
				print(string.format(opts.success_message, picked_date))
			end
			opts.on_success(picked_date)
		else
			-- Cancellation path
			if opts.cancel_message then
				print(opts.cancel_message)
			end

			-- Handle fallback
			local fallback_value = nil
			if opts.fallback_date == "today" then
				fallback_value = get_current_date()
				print("No date selected, using today's date: " .. fallback_value)
			elseif opts.fallback_date ~= "none" and type(opts.fallback_date) == "string" then
				fallback_value = opts.fallback_date
				print("No date selected, using fallback: " .. fallback_value)
			end

			-- Apply auto-fallback or call cancel handler
			if fallback_value and opts.auto_fallback then
				opts.on_success(fallback_value)
			elseif opts.on_cancel then
				opts.on_cancel()
			end
		end
	end)
end

-- Specialized helper for form field updates with refresh
function M.update_form_field_with_date(field_name, form_data, refresh_callback)
	M.get_date_with_action({
		on_success = function(picked_date)
			form_data[field_name] = picked_date
			if refresh_callback then
				refresh_callback()
			end
		end,
		cancel_message = "Date selection cancelled"
	})
end

-- Specialized helper for todo creation workflows
function M.create_todo_with_date(todo_params, date_field, completion_callback)
	M.get_date_with_action({
		on_success = function(picked_date)
			todo_params[date_field] = picked_date
			local success = M.add_todo(
				todo_params.description,
				todo_params.category,
				todo_params.tags,
				todo_params.due_date,
				todo_params.show_date
			)
			
			if success then
				print("✓ " .. (todo_params.category or "Personal") .. " todo added: " .. todo_params.description)
			else
				print("✗ Failed to add todo")
			end
			
			if completion_callback then
				completion_callback(success)
			end
		end,
		fallback_date = "today",
		auto_fallback = true
	})
end

-- ========================================
-- DATE PICKER IMPLEMENTATION (SIMPLIFIED FOR TESTING)
-- ========================================

-- Simplified date picker for testing (stub of the actual calendar implementation)
function M.get_date_input(callback)
	-- In the real implementation, this would show a floating calendar window
	-- For testing purposes, we'll simulate with a simple input prompt
	vim.ui.input({
		prompt = "Enter date (mm-dd-yyyy) or leave empty to cancel: ",
		default = get_current_date(),
	}, function(input)
		if input and input ~= "" then
			-- Enhanced date validation
			if input:match("^%d%d%-%d%d%-%d%d%d%d$") then
				-- Parse the date components
				local month, day, year = input:match("(%d%d)%-(%d%d)%-(%d%d%d%d)")
				month, day, year = tonumber(month), tonumber(day), tonumber(year)
				
				-- Validate date ranges
				if month >= 1 and month <= 12 and day >= 1 and day <= 31 and year >= 1900 then
					-- Additional validation for days per month
					local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
					
					-- Check for leap year
					if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
						days_in_month[2] = 29
					end
					
					if day <= days_in_month[month] then
						callback(input)
					else
						print("Invalid date: " .. input .. " (day " .. day .. " doesn't exist in month " .. month .. ")")
						callback(nil)
					end
				else
					print("Invalid date: " .. input .. " (month: 1-12, day: 1-31, year: >=1900)")
					callback(nil)
				end
			else
				print("Invalid date format. Use mm-dd-yyyy")
				callback(nil)
			end
		else
			callback(nil) -- User cancelled
		end
	end)
end

-- ========================================
-- MISSING FUNCTIONS (STUBS FOR COMPATIBILITY)
-- ========================================

-- Initialize todo system (stub for compatibility)
function M.init_todo_files()
	-- This is a stub - the actual initialization would create directories and files
	-- For testing purposes, we assume the files already exist
	return true
end

-- Add todo function (simplified for testing)
function M.add_todo(description, category, tags, due_date, show_date)
	-- This is a stub - the actual function would write to todo files
	-- For testing purposes, we just simulate success
	if description and description ~= "" then
		return true
	end
	return false
end

-- Setup todo syntax highlighting (stub for compatibility)
function M.setup_todo_syntax()
	-- This is a stub - the actual function would setup syntax highlighting
	-- For testing purposes, we skip syntax setup
	return true
end

-- Highlight due dates with colors (stub for compatibility)
function M.highlight_due_dates_with_colors()
	-- This is a stub - the actual function would highlight due dates
	-- For testing purposes, we skip highlighting
	return true
end

-- ========================================
-- TEST COMMANDS
-- ========================================

-- Create test commands for our refactored functions
vim.api.nvim_create_user_command("TestFilterDue", function()
	M.filter_buffer_by_due_dates()
end, { desc = "Test filter by due dates" })

vim.api.nvim_create_user_command("TestFilterMedicine", function()
	M.filter_buffer_by_category("Medicine")
end, { desc = "Test filter by Medicine category" })

vim.api.nvim_create_user_command("TestFilterOMS", function()
	M.filter_buffer_by_category("OMS")
end, { desc = "Test filter by OMS category" })

vim.api.nvim_create_user_command("TestFilterPersonal", function()
	M.filter_buffer_by_category("Personal")
end, { desc = "Test filter by Personal category" })

vim.api.nvim_create_user_command("TestShowAll", function()
	M.show_all_todos()
end, { desc = "Test show all todos" })

vim.api.nvim_create_user_command("TestFilterToday", function()
	M.filter_buffer_by_today()
end, { desc = "Test filter today's todos" })

vim.api.nvim_create_user_command("TestFilterPastDue", function()
	M.filter_buffer_by_past_due()
end, { desc = "Test filter past due todos" })

vim.api.nvim_create_user_command("TestFilterUrgent", function()
	M.filter_buffer_by_today_and_past_due()
end, { desc = "Test filter urgent todos" })

-- ========================================
-- PHASE 2 DATE PICKER TEST COMMANDS
-- ========================================

vim.api.nvim_create_user_command("TestDatePicker", function()
	print("Testing basic date picker utility...")
	M.get_date_with_action({
		on_success = function(date)
			print("✅ Selected date: " .. date)
		end,
		on_cancel = function()
			print("❌ Date selection cancelled")
		end,
		cancel_message = "No date selected"
	})
end, { desc = "Test basic date picker utility" })

vim.api.nvim_create_user_command("TestDatePickerFallback", function()
	print("Testing date picker with fallback to today...")
	M.get_date_with_action({
		on_success = function(date)
			print("✅ Using date: " .. date)
		end,
		fallback_date = "today",
		auto_fallback = true
	})
end, { desc = "Test date picker with auto-fallback" })

vim.api.nvim_create_user_command("TestCreateTodo", function()
	print("Testing todo creation with date picker...")
	M.create_todo_with_date({
		description = "Test todo from Phase 2",
		category = "Personal",
		tags = {"test"},
		due_date = "",
		show_date = ""
	}, "due_date", function(success)
		print("Todo creation " .. (success and "succeeded" or "failed"))
	end)
end, { desc = "Test todo creation with date picker" })

-- ========================================
-- PHASE 3: CONTINUATION WORKFLOW CONSOLIDATION UTILITIES
-- ========================================

-- State for command-line continuation workflows
M._continuation_state = {
	active = false,
	description = "",
	category = "",
	tags = "",
	due_date = "",
	show_date = "",
	waiting_for = nil, -- "show_date" or "due_date"
}

-- Parse continuation input and return command type and validity
local function parse_continuation_input(input, expected_command)
	input = input or ""
	
	if input == "" then
		return "finish", true
	elseif input:match("/" .. expected_command) then
		return expected_command, true  
	else
		return "invalid", false
	end
end

-- Check if show date has been reached (stub for compatibility)
local function is_show_date_reached(show_date)
	if not show_date or show_date == "" then
		return true
	end
	
	-- Simple date comparison (stub implementation)
	local current_date = os.date("%Y-%m-%d")
	return show_date <= current_date
end

-- Format success message based on todo state and scheduling
local function format_todo_success_message(state)
	local is_scheduled = not is_show_date_reached(state.show_date)
	local has_both_dates = state.show_date ~= "" and state.due_date ~= "" and state.show_date ~= state.due_date
	
	if is_scheduled and has_both_dates then
		return "✓ " .. state.category .. " todo scheduled: " .. state.description 
			.. " [Show: " .. state.show_date .. "] [Due: " .. state.due_date .. "]"
	elseif state.due_date and state.due_date ~= "" then
		local show_display = has_both_dates and " [Show: " .. state.show_date .. "]" or ""
		return "✓ " .. state.category .. " todo added: " .. state.description 
			.. show_display .. " [Due: " .. state.due_date .. "]"
	else
		return "✓ " .. state.category .. " todo added: " .. state.description
	end
end

-- Unified continuation workflow processor
function M.process_continuation_workflow(input, context)
	local state = M._continuation_state
	
	if not state.active then
		return
	end
	
	-- Reset state
	M._continuation_state.active = false
	
	local command_type, is_valid = parse_continuation_input(input, context.expected_command)
	
	if command_type == "finish" then
		-- User pressed Enter, add todo with current dates
		local success = M.add_todo(state.description, state.category, state.tags, state.due_date, state.show_date)
		if success then
			print(format_todo_success_message(state))
		else
			print("✗ Failed to add todo")
		end
		
	elseif command_type == context.expected_command then
		-- User wants to add additional date, get date input
		M.get_date_input(function(picked_date)
			if picked_date then
				state[context.date_field] = picked_date
			else
				print("No " .. context.expected_command .. " date selected, keeping current dates")
			end
			
			-- Add todo with final dates
			local success = M.add_todo(state.description, state.category, state.tags, state.due_date, state.show_date)
			if success then
				print(format_todo_success_message(state))
			else
				print("✗ Failed to add todo")
			end
		end)
		
	else
		-- Invalid input, cancel
		print("Todo cancelled. Use /" .. context.expected_command .. " to add " .. context.expected_command .. " date or press Enter to finish.")
	end
end

-- Process continuation input after due date selection
function M.process_continuation(input)
	M.process_continuation_workflow(input, {
		expected_command = "show",
		date_field = "show_date"
	})
end

-- Process continuation input after show date selection  
function M.process_show_continuation(input)
	M.process_continuation_workflow(input, {
		expected_command = "due", 
		date_field = "due_date"
	})
end

-- ========================================
-- PHASE 3 TEST COMMANDS
-- ========================================

vim.api.nvim_create_user_command("TestContinuationDue", function()
	-- Simulate continuation after due date selection
	M._continuation_state = {
		active = true,
		description = "Test due continuation",
		category = "Personal",
		tags = "",
		due_date = "2025-09-15",
		show_date = "2025-09-15",
	}
	
	print("Testing due continuation workflow. Enter '/show' for show date or Enter to finish:")
	local input = vim.fn.input("Continuation: ")
	M.process_continuation(input)
end, { desc = "Test Phase 3 due continuation workflow" })

vim.api.nvim_create_user_command("TestContinuationShow", function()
	-- Simulate continuation after show date selection
	M._continuation_state = {
		active = true,
		description = "Test show continuation",
		category = "Work",
		tags = "",
		due_date = "2025-09-20",
		show_date = "2025-09-10",
	}
	
	print("Testing show continuation workflow. Enter '/due' for due date or Enter to finish:")
	local input = vim.fn.input("Continuation: ")
	M.process_show_continuation(input)
end, { desc = "Test Phase 3 show continuation workflow" })

return M