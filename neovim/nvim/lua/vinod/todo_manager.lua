-- Description: Core logic for Vinod's Todo Manager plugin
local M = {}

-- ========================================
-- CONFIGURATION
-- ========================================

M.config = {
	todo_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo",
	notebook_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook",
	active_file = "active-todos.md",
	completed_file = "completed-todos.md",
	date_format = "%m-%d-%Y",
	categories = { "Medicine", "OMS", "Personal" },
	category_icons = {
		-- Medicine = "💊",
		Medicine = "󰿷",
		OMS = "󰇄",
		Personal = "",
	},
}

-- ========================================
-- CORE FUNCTIONS (Essential for todo_commands.lua)
-- ========================================

-- Delegate to dates module
local function is_show_date_reached(date_str)
	return require("todo-manager.dates").is_show_date_reached(date_str)
end

-- Delegate to storage module
function M.get_active_todos()
	return require("todo-manager.storage").get_active_todos()
end

function M.get_completed_todos()
	return require("todo-manager.storage").get_completed_todos()
end

function M.get_all_todos_from_active_file()
	return require("todo-manager.storage").get_all_todos_from_active_file()
end

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

	-- Toggle completion status
	todo.completed = not todo.completed

	-- Set appropriate date
	local current_date = os.date("%m-%d-%Y")
	if todo.completed then
		todo.completion_date = current_date
		todo.added_date = ""
	else
		todo.completion_date = ""
		if not todo.added_date or todo.added_date == "" then
			todo.added_date = current_date
		end
	end

	-- Format the new line
	local new_line = M.format_todo_line(todo)

	-- Replace the current line
	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

	-- Handle file movement if needed
	local current_file = vim.api.nvim_buf_get_name(0)
	local active_file_path = M.config.todo_dir .. "/" .. M.config.active_file
	local completed_file_path = M.config.todo_dir .. "/" .. M.config.completed_file

	if current_file == active_file_path and todo.completed then
		-- Remove from current buffer and add to completed file
		vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

		local completed_todos = M.get_completed_todos()
		table.insert(completed_todos, todo)

		local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
		M.write_todos_to_file(M.config.completed_file, completed_todos, completed_header, "storage")

		print("✓ Todo completed and moved to completed list")
	elseif current_file == completed_file_path and not todo.completed then
		-- Remove from current buffer and add to active file
		vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

		local active_todos = M.get_all_todos_from_active_file()
		table.insert(active_todos, todo)

		local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
		M.write_todos_to_file(M.config.active_file, active_todos, active_header, "storage")

		print("↶ Todo uncompleted and moved back to active list")
	else
		local status = todo.completed and "completed" or "uncompleted"
		print("✓ Todo " .. status)
	end

	return true
end

-- List active todos (for command compatibility)
function M.list_active_todos(category)
	local todos = M.get_active_todos()

	-- Filter by category if specified
	if category then
		local filtered = {}
		for _, todo in ipairs(todos) do
			if todo.category == category then
				table.insert(filtered, todo)
			end
		end
		todos = filtered
	end

	if #todos == 0 then
		print("No active todos found" .. (category and " for " .. category or ""))
		return
	end

	print("Active Todos" .. (category and " - " .. category or "") .. " (" .. #todos .. "):")
	print(string.rep("=", 40))

	for i, todo in ipairs(todos) do
		local icon = M.config.category_icons[todo.category] or "📝"
		local line = string.format("%d. %s %s", i, icon, todo.description)

		-- Add due date with color coding
		if todo.due_date and todo.due_date ~= "" then
			if is_past_due(todo.due_date) then
				line = line .. " [OVERDUE: " .. todo.due_date .. "]"
			elseif is_due_today(todo.due_date) then
				line = line .. " [Due TODAY: " .. todo.due_date .. "]"
			else
				line = line .. " [Due: " .. todo.due_date .. "]"
			end
		end

		-- Add tags
		if todo.tags and type(todo.tags) == "table" and #todo.tags > 0 then
			line = line .. " #" .. table.concat(todo.tags, " #")
		elseif todo.tags and type(todo.tags) == "string" and todo.tags ~= "" then
			line = line .. " " .. todo.tags
		end

		print(line)
	end
end

-- Delegate to parser module
function M.format_todo_line(todo, context)
	return require("todo-manager.parser").format_todo_line(todo, context)
end

-- Create and open a filtered active todos view
-- Toggle todo completion in filtered view
function M.toggle_todo_in_filtered_view()
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	-- Check if current line is a todo
	local todo = M.parse_todo_line(line)
	if not todo then
		return false
	end

	-- Make buffer temporarily modifiable
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "readonly", false)

	-- Toggle completion status
	todo.completed = not todo.completed

	-- Set appropriate date
	local current_date = os.date("%m-%d-%Y")
	if todo.completed then
		todo.completion_date = current_date
		todo.added_date = ""
	else
		todo.completion_date = ""
		if not todo.added_date or todo.added_date == "" then
			todo.added_date = current_date
		end
	end

	-- Update the real active file
	local active_todos = M.read_todos_from_file(M.config.active_file)
	local updated = false
	for i, existing_todo in ipairs(active_todos) do
		if existing_todo.description == todo.description and existing_todo.category == todo.category then
			active_todos[i] = todo
			updated = true
			break
		end
	end

	if updated then
		-- Write updated todos back to file
		if todo.completed then
			-- Move to completed file
			local completed_todos = M.get_completed_todos()
			table.insert(completed_todos, todo)
			local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
			M.write_todos_to_file(M.config.completed_file, completed_todos, completed_header, "storage")

			-- Remove from active file
			local remaining_todos = {}
			for _, t in ipairs(active_todos) do
				if not (t.description == todo.description and t.category == todo.category) then
					table.insert(remaining_todos, t)
				end
			end
			local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
			M.write_todos_to_file(M.config.active_file, remaining_todos, active_header, "storage")

			print("✓ Todo completed and moved to completed list")
		else
			-- Update active file
			local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
			M.write_todos_to_file(M.config.active_file, active_todos, active_header, "storage")
			print("↶ Todo uncompleted")
		end

		-- Store cursor position before refresh
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local target_line = math.max(1, cursor_pos[1])

		-- Refresh the filtered view
		M.open_filtered_active_view()

		-- Restore cursor position, adjusting for potential line changes
		local total_lines = vim.api.nvim_buf_line_count(0)
		local restore_line = math.min(target_line, total_lines)
		vim.api.nvim_win_set_cursor(0, { restore_line, cursor_pos[2] })
	else
		print("⚠ Could not find matching todo to update")
	end

	return true
end

function M.open_filtered_active_view()
	local active_todos = M.get_active_todos()

	-- Check if filtered view buffer already exists
	local buf_name = "Active Todos"
	local existing_buf = vim.fn.bufnr(buf_name)

	local buf
	if existing_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_buf) then
		-- Reuse existing buffer
		buf = existing_buf
		-- Make buffer modifiable first, then clear content
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_option(buf, "readonly", false)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
	else
		-- Create a new scratch buffer
		buf = vim.api.nvim_create_buf(false, true)

		-- Set buffer options
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buf, "swapfile", false)
		vim.api.nvim_buf_set_name(buf, buf_name)
	end

	-- Create content lines
	local lines = {}
	table.insert(lines, "# Active Todos")
	table.insert(lines, "")
	table.insert(lines, "Showing " .. #active_todos .. " active todos")
	table.insert(lines, "")

	-- Add filtered todos with active context (hides show dates)
	for _, todo in ipairs(active_todos) do
		table.insert(lines, M.format_todo_line(todo, "active"))
	end

	-- Ensure buffer is modifiable before setting content
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "readonly", false)

	-- Set buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set markdown filetype to get proper checkbox rendering
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	-- Set buffer as read-only (but will be made modifiable during toggle)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "readonly", true)

	-- Open buffer in current window
	vim.api.nvim_set_current_buf(buf)

	-- Apply todo syntax overlays with multiple timing strategies
	-- Immediate attempt
	M.setup_todo_syntax()

	-- Deferred attempt (in case immediate fails)
	vim.defer_fn(function()
		M.setup_todo_syntax()
	end, 100)

	-- Final attempt after longer delay
	vim.defer_fn(function()
		M.setup_todo_syntax()
	end, 300)

	-- Set up keybindings for filtered view
	M.setup_todo_buffer_keybindings(buf)

	local _filter = M.get_current_filter()
	if _filter then
		print("✓ Opened filtered active todos view (" .. _filter .. ")")
	else
		print("✓ Opened active todos view")
	end
end

-- ========================================
-- KEYBINDING SETUP UTILITIES
-- ========================================

-- Set up common keybindings for todo buffers (filtered views, etc.)
function M.setup_todo_buffer_keybindings(buf)
	vim.keymap.set("n", "tt", function()
		M.toggle_todo_in_filtered_view()
	end, { buffer = buf, desc = "Toggle todo completion in filtered view" })

	vim.keymap.set("n", "<leader>te", function()
		M.edit_todo_modal()
	end, { buffer = buf, desc = "Edit todo on current line" })

	vim.keymap.set("n", "<leader>tz", function()
		M.create_or_open_note_from_todo()
	end, { buffer = buf, desc = "Create or open zk note from todo" })

	vim.keymap.set("n", "<leader>tc", function()
		local file_path = M.config.todo_dir .. "/" .. M.config.completed_file
		vim.cmd("edit " .. file_path)
	end, { buffer = buf, desc = "Open completed todos file" })
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Delegate to dates module
local function get_current_date()
	return require("todo-manager.dates").get_current_date()
end

-- Global functions (referenced as bare globals elsewhere in this file)
function is_past_due(date_str)
	return require("todo-manager.dates").is_past_due(date_str)
end

function is_due_today(date_str)
	return require("todo-manager.dates").is_due_today(date_str)
end

-- get_file_path moved to storage module

-- Delegate to parser module
function M.parse_todo_line(line)
	return require("todo-manager.parser").parse_todo_line(line)
end

-- Delegate to dates module
function M.resolve_date_shortcut(keyword)
	return require("todo-manager.dates").resolve_date_shortcut(keyword)
end

-- ========================================
-- COMMAND CONTINUATION WORKFLOW
-- ========================================

-- Handle command continuation workflow for quick todo commands
function M.handle_command_continuation(
	description,
	category,
	tags,
	due_date,
	show_date,
	use_show_calendar,
	use_due_calendar,
	command_prefix
)
	if not use_show_calendar and not use_due_calendar then
		return false -- No continuation needed
	end

	-- Note: Date logic rules are handled by calling function before this point
	-- This function only handles calendar picker workflows

	-- Handle calendar pickers
	if use_show_calendar or use_due_calendar then
		local function add_todo_with_dates()
			local success = M.add_todo(description, category, tags, due_date, show_date)
			if success then
				local cat_display = category and category ~= "" and category or "Personal"
				local show_display = show_date and show_date ~= "" and " [Show: " .. show_date .. "]" or ""
				local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
				print("✓ " .. cat_display .. " todo added: " .. description .. show_display .. due_display)
			else
				print("✗ Failed to add todo")
			end
		end

		local function handle_due_date_picker()
			if use_due_calendar then
				M.get_date_input(function(picked_due_date)
					if picked_due_date then
						due_date = picked_due_date
					else
						due_date = os.date("%m-%d-%Y") -- Today's date in mm-dd-yyyy format
						print("No due date selected, using today's date: " .. due_date)
					end
					add_todo_with_dates()
				end)
			else
				add_todo_with_dates()
			end
		end

		local function handle_show_date_picker()
			if use_show_calendar then
				M.get_date_input(function(picked_show_date)
					if picked_show_date then
						show_date = picked_show_date
					else
						show_date = os.date("%m-%d-%Y") -- Today's date in mm-dd-yyyy format
						print("No show date selected, using today's date: " .. show_date)
					end
					handle_due_date_picker()
				end)
			else
				handle_due_date_picker()
			end
		end

		-- Start the sequential picker process
		handle_show_date_picker()
		return true -- Handled
	end

	return false -- Not handled
end

-- ========================================
-- SCHEDULED AND UPCOMING TODO FUNCTIONS
-- ========================================

-- Delegate to storage module
function M.get_scheduled_todos()
	return require("todo-manager.storage").get_scheduled_todos()
end

function M.get_upcoming_todos(days)
	return require("todo-manager.storage").get_upcoming_todos(days)
end

-- Display todos with a title
function M.display_todos(todos, title)
	if #todos == 0 then
		print(title .. ": No todos found")
		return
	end

	print("\n" .. title .. ":")
	print(string.rep("=", #title + 1))

	for i, todo in ipairs(todos) do
		local icon = M.config.category_icons[todo.category] or "📝"
		local tags_str = ""
		if todo.tags and #todo.tags > 0 then
			tags_str = " #" .. table.concat(todo.tags, " #")
		end

		local show_str = ""
		if todo.show_date and todo.show_date ~= "" then
			show_str = " [Show: " .. todo.show_date .. "]"
		end

		local due_str = ""
		if todo.due_date and todo.due_date ~= "" then
			due_str = " [Due: " .. todo.due_date .. "]"
		end

		print(string.format("%2d. %s %s%s%s%s", i, icon, todo.description, tags_str, show_str, due_str))
	end
	print("")
end

-- ========================================
-- IN-PLACE CATEGORY FILTERING SYSTEM
-- ========================================

-- Global filter state
-- Filter state is now managed by categories module
-- M.current_filter kept as a getter for backward compatibility in remaining monolith code
M.current_filter = nil -- Will be replaced; use M.get_current_filter() instead

-- Delegate to categories module
function M.get_current_filter()
	return require("todo-manager.categories").get_current_filter()
end

function M.set_category_filter(category)
	require("todo-manager.categories").set_category_filter(category)
end

function M.clear_category_filter()
	require("todo-manager.categories").clear_category_filter()
end

function M.validate_category(name)
	return require("todo-manager.categories").validate_category(name)
end

function M.get_category_todo_counts()
	return require("todo-manager.categories").get_category_todo_counts()
end

-- Apply category filter to current view (in-place)
function M.apply_category_filter_to_current_view()
	local buf_name = vim.api.nvim_buf_get_name(0)

	-- Check if we're in a todo buffer that supports filtering
	if buf_name:match("Active Todos") or buf_name:match("todo") then
		-- Refresh the current view with filter applied
		M.refresh_filtered_view_with_state()
	end
end

-- Refresh filtered view maintaining current filter state
function M.refresh_filtered_view_with_state()
	local current_filter = M.get_current_filter()
	local all_todos = M.get_active_todos()
	local filtered_todos = all_todos

	-- Apply category filter if active
	if current_filter then
		filtered_todos = {}
		for _, todo in ipairs(all_todos) do
			if todo.category == current_filter then
				table.insert(filtered_todos, todo)
			end
		end
	end

	-- Update buffer name to reflect filter state
	local buffer_name
	if current_filter then
		if #filtered_todos == 0 then
			buffer_name = "Active Todos - " .. current_filter .. " Filter (No todos found)"
		else
			buffer_name = "Active Todos - " .. current_filter .. " Filter"
		end
	else
		buffer_name = "Active Todos"
	end

	-- Create or update buffer content
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(buf, buffer_name)

	-- Generate header with filter information
	local lines = {}
	table.insert(lines, "# " .. buffer_name)
	table.insert(lines, "")

	if current_filter then
		if #filtered_todos == 0 then
			table.insert(lines, "No todos found in " .. current_filter .. " category")
			table.insert(lines, "Use :TodoFilter Clear or <leader>tf to change filter")
		else
			local hidden_count = #all_todos - #filtered_todos
			table.insert(
				lines,
				"Showing "
					.. #filtered_todos
					.. " "
					.. current_filter
					.. " todos ("
					.. hidden_count
					.. " others hidden)"
			)
		end
	else
		table.insert(lines, "Showing all " .. #filtered_todos .. " todos")
	end

	table.insert(lines, "")

	-- Add filtered todos
	for _, todo in ipairs(filtered_todos) do
		table.insert(lines, M.format_todo_line(todo, "active"))
	end

	-- Update buffer content and set filetype first
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "readonly", false)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "readonly", true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

	-- Apply todo syntax overlays with multiple timing strategies
	-- Immediate attempt
	M.setup_todo_syntax()

	-- Deferred attempts to ensure it works
	vim.defer_fn(function()
		M.setup_todo_syntax()
	end, 100)

	vim.defer_fn(function()
		M.setup_todo_syntax()
	end, 300)
end

-- Delegate to categories module
function M.update_static_categories(new_category)
	return require("todo-manager.categories").update_static_categories(new_category)
end

function M.remove_category_with_checks(category)
	return require("todo-manager.categories").remove_category_with_checks(category)
end

function M.add_new_category(name, icon)
	return require("todo-manager.categories").add_new_category(name, icon)
end

-- ========================================
-- DATE PICKER CONSOLIDATION UTILITIES (PHASE 2)
-- ========================================

-- Consolidated date picker utility function
-- Handles the most common date picker usage patterns
function M.get_date_with_action(options)
	-- Default options
	local opts = vim.tbl_extend("force", {
		on_success = nil, -- Required: function(picked_date)
		on_cancel = nil, -- Optional: function()
		fallback_date = "none", -- "today", "none", or specific date string
		cancel_message = nil, -- Optional: custom cancel message
		success_message = nil, -- Optional: success message template
		auto_fallback = false, -- Auto-apply fallback if cancelled
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
		cancel_message = "Date selection cancelled",
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
		auto_fallback = true,
	})
end

-- ========================================
-- DATE PICKER IMPLEMENTATION (FULL CALENDAR)
-- ========================================

-- Show interactive calendar date picker
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

-- Wrapper function for compatibility with existing code
function M.get_date_input(callback)
	M.show_date_picker(callback)
end

-- ========================================
-- MISSING FUNCTIONS (STUBS FOR COMPATIBILITY)
-- ========================================

-- Delegate to storage module
function M.read_todos_from_file(filename)
	return require("todo-manager.storage").read_todos_from_file(filename)
end

function M.write_todos_to_file(filename, todos, header, context)
	return require("todo-manager.storage").write_todos_to_file(filename, todos, header, context)
end

function M.init_todo_files()
	return require("todo-manager.storage").init_todo_files()
end

function M.add_todo(description, category, tags, due_date, show_date)
	return require("todo-manager.storage").add_todo(description, category, tags, due_date, show_date)
end

-- Refresh filtered view if it exists and is open
function M.refresh_filtered_view_if_open()
	-- Find any buffer with "Active Todos" in the name (handles both filtered and unfiltered)
	local target_buf = nil
	local buffers = vim.api.nvim_list_bufs()

	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			local buf_name = vim.api.nvim_buf_get_name(buf)
			local buf_basename = vim.fn.fnamemodify(buf_name, ":t")
			if buf_basename:match("Active Todos") then
				target_buf = buf
				break
			end
		end
	end

	-- Check if the filtered view buffer exists and is displayed in any window
	if target_buf then
		-- Check if buffer is displayed in any window
		local windows = vim.api.nvim_list_wins()
		local is_displayed = false
		for _, win in ipairs(windows) do
			if vim.api.nvim_win_get_buf(win) == target_buf then
				is_displayed = true
				break
			end
		end

		-- If buffer is displayed, refresh it
		if is_displayed then
			-- Store current window and buffer
			local current_win = vim.api.nvim_get_current_win()
			local current_buf = vim.api.nvim_get_current_buf()

			-- Store cursor position from filtered view if it's the current buffer
			local cursor_line = 1
			if current_buf == target_buf then
				cursor_line = vim.api.nvim_win_get_cursor(current_win)[1]
			end

			-- Switch to filtered view window temporarily to refresh
			for _, win in ipairs(windows) do
				if vim.api.nvim_win_get_buf(win) == target_buf then
					vim.api.nvim_set_current_win(win)
					-- Use filter-aware refresh instead of the old method
					M.refresh_filtered_view_with_state()

					-- Restore cursor position if we stored one
					if current_buf == target_buf then
						local line_count = vim.api.nvim_buf_line_count(target_buf)
						if cursor_line <= line_count then
							vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })
						end
					end

					break
				end
			end

			-- Restore original window if it's still valid and different
			if vim.api.nvim_win_is_valid(current_win) and current_win ~= vim.api.nvim_get_current_win() then
				vim.api.nvim_set_current_win(current_win)
			end
		end
	end
end

-- Setup todo syntax highlighting as overlay on markdown
function M.setup_todo_syntax()
	-- Only apply to markdown buffers (our todo buffers)
	if vim.bo.filetype ~= "markdown" then
		return false
	end

	-- Apply todo syntax overlays to markdown base

	-- Don't clear existing syntax - keep markdown base
	-- Add todo-specific patterns with explicit containedin to override markdown
	vim.cmd([[
		" Clear only previous todo syntax, keep markdown
		silent! syntax clear TodoIcon
		silent! syntax clear TodoIconMedicine
		silent! syntax clear TodoIconOMS
		silent! syntax clear TodoIconPersonal
		silent! syntax clear TodoIconDefault
		silent! syntax clear TodoTag
		silent! syntax clear TodoShowDate
		silent! syntax clear TodoDueDate
		silent! syntax clear TodoAddedDate
		silent! syntax clear TodoNoteLink

		" Todo-specific patterns with high priority (using containedin=ALL)
		syntax match TodoTag /#\w\+/ containedin=ALL
		syntax match TodoShowDate /\[Show: [0-9-]\+\]/ containedin=ALL
		syntax match TodoDueDate /\[Due: [0-9-]\+\]/ containedin=ALL
		syntax match TodoAddedDate /([0-9-]\+)$/ containedin=ALL
		
		" Handle emoji icons separately (they can cause issues in syntax patterns)
		syntax match TodoIconMedicine /💊/ containedin=ALL
		syntax match TodoIconOMS /🛠️/ containedin=ALL
		syntax match TodoIconPersonal /🏡/ containedin=ALL
		syntax match TodoIconDefault /📝/ containedin=ALL
		syntax match TodoNoteLink /󰈙/ containedin=ALL

		" Override markdown math syntax ONLY in todo lines to prevent teal $ coloring
		syntax match TodoLineNoMath /^- \[\s\?\].*$/ contains=@NoSpell transparent
		syntax match TodoLineDoneNoMath /^- \[x\].*$/ contains=@NoSpell transparent
		
		" Disable math highlighting in todo lines by clearing it in those contexts
		syntax region mathIgnore matchgroup=todoMath start=/\$/ end=/\$/ contained containedin=TodoLineNoMath,TodoLineDoneNoMath concealends
	]])

	-- Set up highlight groups with explicit priority
	vim.cmd([[
		highlight! TodoTag ctermfg=blue guifg=#569cd6 gui=bold
		highlight! TodoShowDate ctermfg=cyan guifg=#4EC9B0
		highlight! TodoAddedDate ctermfg=gray guifg=#767676
		highlight! mathIgnore ctermfg=white guifg=#ffffff
		highlight! todoMath ctermfg=white guifg=#ffffff
		
		" Emoji icon highlights
		highlight! TodoIconMedicine ctermfg=yellow guifg=#ffd700
		highlight! TodoIconOMS ctermfg=yellow guifg=#ffd700
		highlight! TodoIconPersonal ctermfg=yellow guifg=#ffd700
		highlight! TodoIconDefault ctermfg=yellow guifg=#ffd700
		highlight! TodoNoteLink ctermfg=yellow guifg=#ffd700
	]])

	-- Set up due date color highlighting
	M.highlight_due_dates_with_colors()

	return true
end

-- Highlight due dates with colors based on urgency
function M.highlight_due_dates_with_colors()
	-- Clear existing due date matches
	vim.cmd([[
		silent! syntax clear TodoDueDatePastDue
		silent! syntax clear TodoDueDateToday
		silent! syntax clear TodoDueDateFuture
	]])

	local current_date = get_current_date()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for i, line in ipairs(lines) do
		local due_date = line:match("%[Due: ([0-9-]+)%]")
		if due_date then
			local line_num = i
			if is_past_due(due_date) then
				-- Past due - red
				vim.cmd(string.format(
					[[
					syntax match TodoDueDatePastDue /\[Due: %s\]/ containedin=ALL
				]],
					vim.pesc(due_date)
				))
			elseif due_date == current_date then
				-- Due today - green
				vim.cmd(string.format(
					[[
					syntax match TodoDueDateToday /\[Due: %s\]/ containedin=ALL
				]],
					vim.pesc(due_date)
				))
			else
				-- Future - gray
				vim.cmd(string.format(
					[[
					syntax match TodoDueDateFuture /\[Due: %s\]/ containedin=ALL
				]],
					vim.pesc(due_date)
				))
			end
		end
	end

	-- Set up colors for due dates
	vim.cmd([[
		highlight TodoDueDatePastDue ctermfg=red guifg=#DC143C
		highlight TodoDueDateToday ctermfg=green guifg=#228B22
		highlight TodoDueDateFuture ctermfg=gray guifg=#767676
	]])

	return true
end

-- ========================================
-- TODO MODAL DIALOG
-- ========================================

-- Show interactive todo creation modal
function M.show_todo_modal(options)
	-- Handle optional pre-populated data for edit mode
	options = options or {}

	-- Form state with optional pre-population
	-- Use filtered category if active, otherwise default to "Personal"
	local default_category = M.get_current_filter() or "Personal"
	local form_data = {
		description = options.description or "",
		category = options.category or default_category,
		category_index = 3, -- Will be updated based on category
		show_date = options.show_date or "",
		due_date = options.due_date or "",
		tags = options.tags or {},
	}

	-- Set correct category index for pre-populated data
	local categories = M.config.categories
	for i, cat in ipairs(categories) do
		if cat == form_data.category then
			form_data.category_index = i
			break
		end
	end

	-- Store edit mode data
	local is_edit_mode = options.mode == "edit"
	local original_line_number = options.line_number
	local original_todo = options.original_todo

	-- Create buffer for modal
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "todomodal")

	-- Window dimensions
	local width = 50
	local height = 8

	-- Window options
	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		anchor = "NW",
		style = "minimal",
		border = "single",
		title = is_edit_mode and " Edit Todo " or " Add New Todo ",
		title_pos = "center",
		footer = " Press 's' to submit, 'q' to cancel ",
		footer_pos = "center",
	}

	-- Create window FIRST so it's available to functions
	local win = vim.api.nvim_open_win(buf, true, win_opts)

	-- Function to render form content
	local function render_form()
		local lines = {}

		-- Form fields with proper alignment (note space after colon)
		table.insert(lines, " Description:  " .. form_data.description)
		table.insert(lines, "")
		table.insert(lines, " Category:    " .. form_data.category)
		table.insert(lines, "")
		table.insert(lines, " Show Date:   " .. (form_data.show_date ~= "" and form_data.show_date or "[Not Set]"))
		table.insert(lines, "")
		table.insert(lines, " Due Date:    " .. (form_data.due_date ~= "" and form_data.due_date or "[Not Set]"))

		-- Update buffer content
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
	end

	-- Handle user input for all form interactions
	local function handle_input()
		-- [i] Edit Description inline
		vim.keymap.set("n", "i", function()
			-- Make buffer modifiable first
			vim.api.nvim_buf_set_option(buf, "modifiable", true)

			-- Use a more reliable cursor positioning method
			vim.schedule(function()
				-- Get the current line content to calculate exact position
				local current_line = vim.api.nvim_get_current_line()
				local colon_pos = current_line:find(":")

				if colon_pos then
					-- Position cursor after "Description: " (accounting for spaces)
					local desc_start = current_line:find(":%s*", colon_pos)
					if desc_start then
						-- Find where the actual description text begins
						local desc_text_start = desc_start + 1
						-- Skip any spaces after colon
						while
							desc_text_start <= #current_line
							and current_line:sub(desc_text_start, desc_text_start) == " "
						do
							desc_text_start = desc_text_start + 1
						end

						-- If there's existing text, go to the end of it
						if form_data.description ~= "" then
							vim.api.nvim_win_set_cursor(win, { 1, #current_line })
						else
							-- If no existing text, position after the spaces following the colon
							vim.api.nvim_win_set_cursor(win, { 1, desc_text_start - 1 })
						end
					else
						-- Fallback: position at end of line
						vim.api.nvim_win_set_cursor(win, { 1, #current_line })
					end
				end

				-- Enter insert mode at current cursor position
				vim.cmd("startinsert")
			end)
		end, { buffer = buf, silent = true })

		-- Handle insert mode exit to capture new description
		vim.keymap.set("i", "<ESC>", function()
			local line = vim.api.nvim_get_current_line()
			-- Use flexible pattern to match any amount of spaces after colon
			local desc = line:match(" Description:%s*(.*)") or ""
			-- Remove trailing whitespace
			desc = desc:gsub("%s+$", "")
			form_data.description = desc
			vim.api.nvim_buf_set_option(buf, "modifiable", false)
			vim.cmd("stopinsert")
			render_form()
		end, { buffer = buf, silent = true })

		-- [j/k] Navigate categories when on category line
		vim.keymap.set("n", "j", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			if cursor[1] == 3 then -- On category line
				form_data.category_index = (form_data.category_index % #M.config.categories) + 1
				form_data.category = M.config.categories[form_data.category_index]
				render_form()
				vim.api.nvim_win_set_cursor(win, { 3, cursor[2] })
			else
				-- Normal j movement
				vim.cmd("normal! j")
			end
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "k", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			if cursor[1] == 3 then -- On category line
				form_data.category_index = form_data.category_index - 1
				if form_data.category_index < 1 then
					form_data.category_index = #M.config.categories
				end
				form_data.category = M.config.categories[form_data.category_index]
				render_form()
				vim.api.nvim_win_set_cursor(win, { 3, cursor[2] })
			else
				-- Normal k movement
				vim.cmd("normal! k")
			end
		end, { buffer = buf, silent = true })

		-- [Enter] Context-sensitive action
		vim.keymap.set("n", "<CR>", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local current_line = cursor[1]

			-- Check which field we're on
			if current_line == 5 then -- Show Date line
				M.get_date_input(function(picked_date)
					if picked_date then
						form_data.show_date = picked_date
						render_form()
					end
				end)
			elseif current_line == 7 then -- Due Date line
				M.get_date_input(function(picked_date)
					if picked_date then
						form_data.due_date = picked_date
						render_form()
					end
				end)
			else -- Submit form
				if form_data.description == "" then
					print("Error: Description is required")
					return
				end

				-- Close modal first
				vim.api.nvim_win_close(win, true)

				if is_edit_mode then
					-- Edit mode: Update existing todo
					local updated_todo = {
						completed = original_todo.completed,
						description = form_data.description,
						category = form_data.category,
						tags = form_data.tags,
						due_date = form_data.due_date,
						show_date = form_data.show_date,
						added_date = original_todo.added_date,
						completion_date = original_todo.completion_date,
					}

					-- Format the new line
					local context = "storage" -- Default context for file storage
					local new_line = M.format_todo_line(updated_todo, context)

					-- Make buffer temporarily modifiable if needed
					local current_buf = vim.api.nvim_get_current_buf()
					local was_modifiable = vim.api.nvim_buf_get_option(current_buf, "modifiable")
					if not was_modifiable then
						vim.api.nvim_buf_set_option(current_buf, "modifiable", true)
						vim.api.nvim_buf_set_option(current_buf, "readonly", false)
					end

					-- Update the line in the current buffer
					vim.api.nvim_buf_set_lines(0, original_line_number - 1, original_line_number, false, { new_line })

					-- Restore original modifiable state
					if not was_modifiable then
						vim.api.nvim_buf_set_option(current_buf, "modifiable", false)
						vim.api.nvim_buf_set_option(current_buf, "readonly", true)
					end

					-- Update the file if we're in a todo file
					local current_file = vim.api.nvim_buf_get_name(0)
					local active_file_path = M.config.todo_dir .. "/" .. M.config.active_file
					local completed_file_path = M.config.todo_dir .. "/" .. M.config.completed_file

					if current_file == active_file_path or current_file == completed_file_path then
						-- Save the file
						vim.cmd("write")
					end

					-- Refresh filtered view if open
					M.refresh_filtered_view_if_open()

					print("✓ Todo updated: " .. form_data.description)
				else
					-- Add mode: Create new todo
					local success = M.add_todo(
						form_data.description,
						form_data.category,
						form_data.tags,
						form_data.due_date,
						form_data.show_date
					)

					if success then
						print("✓ Todo added: " .. form_data.description)
					else
						print("✗ Failed to add todo")
					end
				end
			end
		end, { buffer = buf, silent = true })

		-- [ESC/q] Cancel
		vim.keymap.set("n", "<ESC>", function()
			vim.api.nvim_win_close(win, true)
			print("Todo creation cancelled")
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, true)
			print("Todo creation cancelled")
		end, { buffer = buf, silent = true })

		-- [s] Submit form from anywhere
		vim.keymap.set("n", "s", function()
			if form_data.description == "" then
				print("Error: Description is required")
				return
			end

			-- Close modal first
			vim.api.nvim_win_close(win, true)

			if is_edit_mode then
				-- Edit mode: Update existing todo
				local updated_todo = {
					completed = original_todo.completed,
					description = form_data.description,
					category = form_data.category,
					tags = form_data.tags,
					due_date = form_data.due_date,
					show_date = form_data.show_date,
					added_date = original_todo.added_date,
					completion_date = original_todo.completion_date,
				}

				-- Format the new line
				local context = "storage" -- Default context for file storage
				local new_line = M.format_todo_line(updated_todo, context)

				-- Update the actual todo file directly instead of trying to modify buffer
				-- Find and update the todo in the file
				local all_todos = M.get_all_todos_from_active_file()
				local found = false
				for i, file_todo in ipairs(all_todos) do
					if
						file_todo.description == original_todo.description
						and file_todo.category == original_todo.category
						and file_todo.added_date == original_todo.added_date
					then
						-- Update this todo
						all_todos[i] = updated_todo
						found = true
						break
					end
				end

				if found then
					-- Write the updated todos back to the file
					local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
					M.write_todos_to_file(M.config.active_file, all_todos, active_header, "storage")

					-- Refresh filtered view if open (this will regenerate the view from the updated file)
					M.refresh_filtered_view_if_open()
				else
					print("⚠ Could not find todo to update in file")
				end

				print("✓ Todo updated: " .. form_data.description)
			else
				-- Add mode: Create new todo
				local success = M.add_todo(
					form_data.description,
					form_data.category,
					form_data.tags,
					form_data.due_date,
					form_data.show_date
				)

				if success then
					print("✓ Todo added: " .. form_data.description)
				else
					print("✗ Failed to add todo")
				end
			end
		end, { buffer = buf, silent = true })

		-- [Tab] Navigate between fields
		vim.keymap.set("n", "<Tab>", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local current_line = cursor[1]

			-- Navigate to next field's text entry position
			if current_line <= 1 then -- Description area
				vim.api.nvim_win_set_cursor(win, { 3, 14 }) -- Category text position
			elseif current_line <= 3 then -- Category area
				vim.api.nvim_win_set_cursor(win, { 5, 14 }) -- Show Date text position
			elseif current_line <= 5 then -- Show Date area
				vim.api.nvim_win_set_cursor(win, { 7, 14 }) -- Due Date text position
			else -- Due Date or below
				local desc_len = #form_data.description
				vim.api.nvim_win_set_cursor(win, { 1, 15 + desc_len }) -- Back to Description end
			end
		end, { buffer = buf, silent = true })
	end

	-- Setup input handlers and render initial form
	handle_input()
	render_form()

	-- For edit mode, position cursor at end of description for immediate editing
	if is_edit_mode and form_data.description ~= "" then
		vim.schedule(function()
			vim.cmd("normal! 0") -- Go to beginning of line
			vim.cmd("normal! f:") -- Find the colon
			vim.cmd("normal! 2l") -- Move 2 characters right (past the colon and spaces)
			vim.cmd("normal! E") -- Move to end of current word (end of description)
		end)
	end
end

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

-- Format success message based on todo state and scheduling
local function format_todo_success_message(state)
	local is_scheduled = not is_show_date_reached(state.show_date)
	local has_both_dates = state.show_date ~= "" and state.due_date ~= "" and state.show_date ~= state.due_date

	if is_scheduled and has_both_dates then
		return "✓ "
			.. state.category
			.. " todo scheduled: "
			.. state.description
			.. " [Show: "
			.. state.show_date
			.. "] [Due: "
			.. state.due_date
			.. "]"
	elseif state.due_date and state.due_date ~= "" then
		local show_display = has_both_dates and " [Show: " .. state.show_date .. "]" or ""
		return "✓ "
			.. state.category
			.. " todo added: "
			.. state.description
			.. show_display
			.. " [Due: "
			.. state.due_date
			.. "]"
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
		print(
			"Todo cancelled. Use /"
				.. context.expected_command
				.. " to add "
				.. context.expected_command
				.. " date or press Enter to finish."
		)
	end
end

-- Process continuation input after due date selection
function M.process_continuation(input)
	M.process_continuation_workflow(input, {
		expected_command = "show",
		date_field = "show_date",
	})
end

-- Process continuation input after show date selection
function M.process_show_continuation(input)
	M.process_continuation_workflow(input, {
		expected_command = "due",
		date_field = "due_date",
	})
end

-- ========================================
-- TODO EDITING FUNCTIONALITY
-- ========================================

-- Get todo data from current cursor line
function M.get_current_todo()
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	local todo = M.parse_todo_line(line)
	if not todo then
		return nil
	end

	-- Check if we're in a filtered view (where show dates might be hidden)
	local buf_name = vim.api.nvim_buf_get_name(0)
	if buf_name:match("Active Todos") or buf_name:match("todos") then
		-- We're in a filtered view, need to get the full todo data from the actual file
		-- Match this todo against the full todo list to get complete data
		local all_todos = M.get_all_todos_from_active_file()
		for i, full_todo in ipairs(all_todos) do
			if full_todo.description == todo.description and full_todo.category == todo.category then
				-- Found matching todo, use the full data
				full_todo.line_number = line_num
				return full_todo
			end
		end

		-- If not found in active, check completed todos
		local completed_todos = M.get_completed_todos()
		for _, full_todo in ipairs(completed_todos) do
			if full_todo.description == todo.description and full_todo.category == todo.category then
				full_todo.line_number = line_num
				return full_todo
			end
		end
	end

	-- Add line number for reference
	todo.line_number = line_num
	return todo
end

-- Edit todo modal - reuses existing show_todo_modal with pre-populated data
function M.edit_todo_modal()
	local current_todo = M.get_current_todo()
	if not current_todo then
		print("Current line is not a todo item")
		return
	end

	-- Store the line number and original todo for updating
	local original_line_number = current_todo.line_number
	local original_todo = vim.deepcopy(current_todo)

	-- Call existing modal with pre-populated data and edit mode
	M.show_todo_modal({
		mode = "edit",
		line_number = original_line_number,
		original_todo = original_todo,
		description = current_todo.description or "",
		category = current_todo.category or "Personal",
		show_date = current_todo.show_date or "",
		due_date = current_todo.due_date or "",
		tags = current_todo.tags or {},
	})
end

-- ========================================
-- ZK INTEGRATION FUNCTIONALITY
-- ========================================

-- Get all folders in notebook directory recursively for note placement
local function get_notebook_folders()
	local notebook_dir = M.config.notebook_dir
	local folders = {}

	-- Use find command to get all directories (table args to avoid shell injection)
	local result = vim.fn.system({ "find", notebook_dir, "-maxdepth", "1", "-type", "d" })
	if vim.v.shell_error ~= 0 or not result or result == "" then
		return { "todo" }
	end

	for line in result:gmatch("[^\n]+") do
		-- Get relative path from notebook_dir
		local relative = line:sub(#notebook_dir + 2)
		if relative and relative ~= "" then
			-- Skip hidden directories
			if not relative:match("^%.") and not relative:match("/%.") then
				table.insert(folders, relative)
			end
		end
	end

	-- Ensure "todo" is first (default)
	local todo_index = nil
	for i, folder in ipairs(folders) do
		if folder == "todo" then
			todo_index = i
			break
		end
	end

	if todo_index then
		table.remove(folders, todo_index)
	end
	table.insert(folders, 1, "todo")

	return folders
end

-- Generate unique ID for todo item
local function generate_todo_id(todo)
	-- Create stable ID from description + category + added_date
	-- For older todos without added_date, use current date as fallback
	local added_date = todo.added_date
	if not added_date or added_date == "" then
		added_date = os.date("%m-%d-%Y")
	end

	local base_string = (todo.description or "") .. "|" .. (todo.category or "Personal") .. "|" .. added_date
	-- Simple hash function to create shorter ID
	local hash = 0
	for i = 1, #base_string do
		hash = (hash * 31 + string.byte(base_string, i)) % 1000000
	end
	return "todo_" .. hash
end

-- Create or open zk note from current todo with smart detection
function M.create_or_open_note_from_todo()
	local current_todo = M.get_current_todo()
	if not current_todo then
		print("Current line is not a todo item")
		return
	end

	-- Store cursor position in todo list for return navigation
	local todo_cursor_line = vim.fn.line(".")
	local todo_cursor_col = vim.fn.col(".")

	-- Check if zk command is available
	if vim.fn.executable("zk") ~= 1 then
		print("✗ zk command not found. Please install zk: brew install zk")
		return
	end

	local note_title = current_todo.description
	local todo_id = generate_todo_id(current_todo)

	-- Safe search for existing notes using grep (zk --match doesn't search frontmatter)
	-- Table args avoid shell injection; -F uses fixed string matching; -l returns file paths only
	local search_result = vim.fn.system({
		"grep", "-r", "-F", "-l", "todo_id: " .. todo_id,
		"--include=*.md", M.config.notebook_dir,
	})

	-- If we found an existing note, extract path and open it
	if vim.v.shell_error == 0 and search_result and search_result ~= "" then
		local full_path = vim.trim(search_result:match("([^\n]+)") or "")
		if full_path ~= "" then
			print("📖 Opening existing note: " .. vim.fn.fnamemodify(full_path, ":t"))
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))

			-- Add note link indicator if not already present
			local todo_file = M.config.todo_dir .. "/" .. M.config.active_file
			if vim.fn.filereadable(todo_file) == 1 then
				local lines = vim.fn.readfile(todo_file)
				if lines[todo_cursor_line] then
					local todo_line = lines[todo_cursor_line]
					if not todo_line:find("󰈙", 1, true) then
						local new_line
						if todo_line:match("%[Show:") then
							new_line = todo_line:gsub("(%[Show:)", "󰈙 %1")
						elseif todo_line:match("%[Due:") then
							new_line = todo_line:gsub("(%[Due:)", "󰈙 %1")
						elseif todo_line:match("#%w+") then
							new_line = todo_line:gsub("(#%w+)", "󰈙 %1", 1)
						else
							new_line = todo_line .. " 󰈙"
						end
						lines[todo_cursor_line] = new_line
						vim.fn.writefile(lines, todo_file)
					end
				end
			end

			-- Position cursor at end of Notes section with date stamp if needed
			vim.schedule(function()
				local buf = vim.api.nvim_get_current_buf()
				local total_lines = vim.api.nvim_buf_line_count(buf)
				local all_lines = vim.api.nvim_buf_get_lines(buf, 0, total_lines, false)

				-- Find ## Notes section
				local notes_line = nil
				for i, line in ipairs(all_lines) do
					if line:match("^## Notes") then
						notes_line = i
						break
					end
				end

				if not notes_line then
					vim.fn.cursor(total_lines, 1)
					vim.cmd("startinsert")
					return
				end

				-- Find end of notes section (before --- separator or end of file)
				local insert_line = total_lines
				for i = notes_line + 1, total_lines do
					if all_lines[i] and all_lines[i]:match("^%s*%-%-%-+%s*$") then
						insert_line = i - 1
						break
					end
				end

				-- Check for last date entry (mm/dd/yyyy format)
				local today = os.date("%m/%d/%Y")
				local last_date_found = nil
				for i = insert_line, notes_line + 1, -1 do
					local date_match = all_lines[i] and all_lines[i]:match("^(%d%d/%d%d/%d%d%d%d)%s*$")
					if date_match then
						last_date_found = date_match
						break
					end
				end

				-- Add new date if different from today (or no date exists)
				if last_date_found ~= today then
					-- Add blank line for separation, new date, cursor line
					vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, { "", today, "" })
					vim.fn.cursor(insert_line + 3, 1)
				else
					-- Same date, add blank line for next entry
					vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, { "" })
					vim.fn.cursor(insert_line + 1, 1)
				end
				vim.cmd("startinsert")

				-- Auto-save when leaving insert mode or buffer
				vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
					buffer = 0,
					callback = function()
						if vim.bo.modified then
							vim.cmd("silent! write")
						end
					end,
				})

				-- Return to todo file after saving
				vim.api.nvim_create_autocmd({ "BufWritePost", "WinClosed", "BufDelete" }, {
					buffer = 0,
					once = true,
					callback = function()
						vim.schedule(function()
							local todo_file_path = M.config.todo_dir .. "/" .. M.config.active_file
							if vim.fn.filereadable(todo_file_path) == 1 then
								vim.cmd("edit " .. vim.fn.fnameescape(todo_file_path))
								pcall(vim.fn.cursor, todo_cursor_line, todo_cursor_col)
							end
						end)
					end,
				})
			end)
			return
		end
	end

	-- Note indicator exists but note file not found - warn user
	if current_todo.has_note then
		vim.notify("⚠ Note indicator (󰈙) found but no linked note exists. Creating new note.", vim.log.levels.WARN)
	end

	-- Show folder picker for note placement
	local folders = get_notebook_folders()
	local display_items = {}
	for _, folder in ipairs(folders) do
		if folder == "todo" then
			table.insert(display_items, folder .. " (default)")
		else
			table.insert(display_items, folder)
		end
	end
	require("fzf-lua").fzf_exec(display_items, {
		prompt = "",
		winopts = {
			title = " Select folder ",
			title_pos = "center",
			height = 0.35,
			width = 0.3,
			preview = { hidden = "hidden" },
		},
		fzf_opts = { ["--no-info"] = "", ["--layout"] = "reverse", ["--border"] = "none" },
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					print("Note creation cancelled")
					return
				end
				local selected_folder = selected[1]:gsub(" %(default%)$", "")

		print("📝 Creating note in '" .. selected_folder .. "': " .. note_title)

		local current_date = os.date("%Y-%m-%d")

		-- Create note using zk new command (table args to avoid shell injection)
		local create_result = vim.fn.system({ "zk", "new", selected_folder, "--title", note_title, "--print-path" })

		if vim.v.shell_error ~= 0 or not create_result or create_result == "" then
			print("✗ Failed to create zk note - check if zk repo is initialized")
			return
		end

		local note_path = vim.trim(create_result:match("([^\n\r]+)") or "")
		if note_path == "" then
			print("✗ Could not determine created note path")
			return
		end

		-- Validate note path is within notebook directory (canonicalize to handle symlinks)
		local canonical_path = vim.fn.fnamemodify(note_path, ":p")
		local canonical_notebook = vim.fn.fnamemodify(M.config.notebook_dir, ":p")
		if not vim.startswith(canonical_path, canonical_notebook) then
			print("✗ Note path outside notebook directory: " .. note_path)
			return
		end

		-- Build note content with frontmatter
		local note_content = {
			"---",
			"todo_id: " .. todo_id,
			"category: " .. (current_todo.category or "Personal"),
			"created: " .. current_date,
		}

		if current_todo.tags and type(current_todo.tags) == "table" and #current_todo.tags > 0 then
			table.insert(note_content, "tags: [" .. table.concat(current_todo.tags, ", ") .. "]")
		end
		if current_todo.due_date and current_todo.due_date ~= "" then
			table.insert(note_content, "due_date: " .. current_todo.due_date)
		end
		if
			current_todo.show_date
			and current_todo.show_date ~= ""
			and current_todo.show_date ~= current_todo.due_date
		then
			table.insert(note_content, "show_date: " .. current_todo.show_date)
		end

		table.insert(note_content, "---")
		table.insert(note_content, "")
		table.insert(note_content, "# " .. note_title)
		table.insert(note_content, "")
		table.insert(note_content, "**Category**: " .. (current_todo.category or "Personal"))

		if current_todo.tags and type(current_todo.tags) == "table" and #current_todo.tags > 0 then
			table.insert(note_content, "**Tags**: #" .. table.concat(current_todo.tags, " #"))
		end
		if current_todo.due_date and current_todo.due_date ~= "" then
			table.insert(note_content, "**Due Date**: " .. current_todo.due_date)
		end
		if
			current_todo.show_date
			and current_todo.show_date ~= ""
			and current_todo.show_date ~= current_todo.due_date
		then
			table.insert(note_content, "**Show Date**: " .. current_todo.show_date)
		end

		table.insert(note_content, "**Created**: " .. current_date)
		table.insert(note_content, "")
		table.insert(note_content, "## Original Todo")
		table.insert(note_content, "```")
		table.insert(note_content, M.format_todo_line(current_todo, "storage"))
		table.insert(note_content, "```")
		table.insert(note_content, "")
		table.insert(note_content, "## Notes")
		table.insert(note_content, "")
		table.insert(note_content, os.date("%m/%d/%Y"))
		table.insert(note_content, "")

		local file = io.open(note_path, "w")
		if not file then
			print("✗ Failed to open created note file for writing: " .. note_path)
			return
		end

		for _, line in ipairs(note_content) do
			file:write(line .. "\n")
		end
		file:close()

		vim.cmd("edit " .. vim.fn.fnameescape(note_path))

		vim.schedule(function()
			local total_lines = vim.fn.line("$")
			local notes_line = nil

			for i = 1, total_lines do
				if vim.fn.getline(i):match("^## Notes") then
					notes_line = i
					break
				end
			end

			if notes_line then
				-- Position cursor immediately below date line (## Notes -> blank -> date -> cursor)
				vim.fn.cursor(notes_line + 3, 1)
				vim.cmd("startinsert")
			else
				vim.fn.cursor(total_lines, 1)
				vim.cmd("startinsert")
			end

			-- Auto-save when leaving insert mode or buffer
			vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
				buffer = 0,
				callback = function()
					if vim.bo.modified then
						vim.cmd("silent! write")
					end
				end,
			})

			-- Return to todo file after saving
			vim.api.nvim_create_autocmd("BufWritePost", {
				buffer = 0,
				once = true,
				callback = function()
					local todo_file = M.config.todo_dir .. "/" .. M.config.active_file
					if vim.fn.filereadable(todo_file) == 1 then
						vim.defer_fn(function()
							vim.cmd("edit " .. vim.fn.fnameescape(todo_file))
							pcall(vim.fn.cursor, todo_cursor_line, todo_cursor_col)
						end, 100)
					end
				end,
			})
		end)

		print("✓ Created note in '" .. selected_folder .. "': " .. note_title)

		-- Add note link indicator to todo file
		vim.schedule(function()
			local todo_file = M.config.todo_dir .. "/" .. M.config.active_file
			if vim.fn.filereadable(todo_file) == 1 then
				local lines = vim.fn.readfile(todo_file)
				if lines[todo_cursor_line] then
					local todo_line = lines[todo_cursor_line]
					if not todo_line:find("󰈙", 1, true) then
						local new_line
						if todo_line:match("%[Show:") then
							new_line = todo_line:gsub("(%[Show:)", "󰈙 %1")
						elseif todo_line:match("%[Due:") then
							new_line = todo_line:gsub("(%[Due:)", "󰈙 %1")
						elseif todo_line:match("#%w+") then
							new_line = todo_line:gsub("(#%w+)", "󰈙 %1", 1)
						else
							new_line = todo_line .. " 󰈙"
						end
						lines[todo_cursor_line] = new_line
						vim.fn.writefile(lines, todo_file)
					end
				end
			end
		end)
			end,
		},
	})
end

M._test = {
	generate_todo_id = generate_todo_id,
	is_show_date_reached = is_show_date_reached,
}

return M
