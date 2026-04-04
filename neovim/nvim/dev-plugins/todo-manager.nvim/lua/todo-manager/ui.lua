-- todo-manager/ui.lua
-- Filtered view, syntax highlighting, keybindings, toggle, display

local M = {}

-- Toggle todo completion on current line (raw file editing)
function M.toggle_todo_on_line()
	local tm = require("todo-manager")
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	-- Check if current line is a todo
	local todo = tm.parse_todo_line(line)
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
	local new_line = tm.format_todo_line(todo)

	-- Replace the current line
	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

	-- Handle file movement if needed
	local current_file = vim.api.nvim_buf_get_name(0)
	local active_file_path = tm.config.todo_dir .. "/" .. tm.config.active_file
	local completed_file_path = tm.config.todo_dir .. "/" .. tm.config.completed_file

	if current_file == active_file_path and todo.completed then
		-- Remove from current buffer and add to completed file
		vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

		local completed_todos = tm.get_completed_todos()
		table.insert(completed_todos, todo)

		local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
		tm.write_todos_to_file(tm.config.completed_file, completed_todos, completed_header, "storage")

		print("✓ Todo completed and moved to completed list")
	elseif current_file == completed_file_path and not todo.completed then
		-- Remove from current buffer and add to active file
		vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})

		local active_todos = tm.get_all_todos_from_active_file()
		table.insert(active_todos, todo)

		local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
		tm.write_todos_to_file(tm.config.active_file, active_todos, active_header, "storage")

		print("↶ Todo uncompleted and moved back to active list")
	else
		local status = todo.completed and "completed" or "uncompleted"
		print("✓ Todo " .. status)
	end

	return true
end

-- List active todos (for command compatibility)
function M.list_active_todos(category)
	local tm = require("todo-manager")
	local dates = require("todo-manager.dates")
	local todos = tm.get_active_todos()

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
		local icon = tm.config.category_icons[todo.category] or "📝"
		local line = string.format("%d. %s %s", i, icon, todo.description)

		-- Add due date with color coding
		if todo.due_date and todo.due_date ~= "" then
			if dates.is_past_due(todo.due_date) then
				line = line .. " [OVERDUE: " .. todo.due_date .. "]"
			elseif dates.is_due_today(todo.due_date) then
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

-- Toggle todo completion in filtered view
function M.toggle_todo_in_filtered_view()
	local tm = require("todo-manager")
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	-- Check if current line is a todo
	local todo = tm.parse_todo_line(line)
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
	local active_todos = tm.read_todos_from_file(tm.config.active_file)
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
			local completed_todos = tm.get_completed_todos()
			table.insert(completed_todos, todo)
			local completed_header = "# Completed Todos\n\nManaged by Vinod's Todo Manager"
			tm.write_todos_to_file(tm.config.completed_file, completed_todos, completed_header, "storage")

			-- Remove from active file
			local remaining_todos = {}
			for _, t in ipairs(active_todos) do
				if not (t.description == todo.description and t.category == todo.category) then
					table.insert(remaining_todos, t)
				end
			end
			local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
			tm.write_todos_to_file(tm.config.active_file, remaining_todos, active_header, "storage")

			print("✓ Todo completed and moved to completed list")
		else
			-- Update active file
			local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
			tm.write_todos_to_file(tm.config.active_file, active_todos, active_header, "storage")
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
	local tm = require("todo-manager")
	local active_todos = tm.get_active_todos()

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
		table.insert(lines, tm.format_todo_line(todo, "active"))
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

	local _filter = tm.get_current_filter()
	if _filter then
		print("✓ Opened filtered active todos view (" .. _filter .. ")")
	else
		print("✓ Opened active todos view")
	end
end

-- Set up common keybindings for todo buffers (filtered views, etc.)
function M.setup_todo_buffer_keybindings(buf)
	local tm = require("todo-manager")

	vim.keymap.set("n", "tt", function()
		M.toggle_todo_in_filtered_view()
	end, { buffer = buf, desc = "Toggle todo completion in filtered view" })

	vim.keymap.set("n", "<leader>te", function()
		tm.edit_todo_modal()
	end, { buffer = buf, desc = "Edit todo on current line" })

	vim.keymap.set("n", "<leader>tz", function()
		tm.create_or_open_note_from_todo()
	end, { buffer = buf, desc = "Create or open zk note from todo" })

	vim.keymap.set("n", "<leader>tc", function()
		local file_path = tm.config.todo_dir .. "/" .. tm.config.completed_file
		vim.cmd("edit " .. file_path)
	end, { buffer = buf, desc = "Open completed todos file" })
end

-- Display todos with a title
function M.display_todos(todos, title)
	local tm = require("todo-manager")

	if #todos == 0 then
		print(title .. ": No todos found")
		return
	end

	print("\n" .. title .. ":")
	print(string.rep("=", #title + 1))

	for i, todo in ipairs(todos) do
		local icon = tm.config.category_icons[todo.category] or "📝"
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
	local tm = require("todo-manager")
	local current_filter = tm.get_current_filter()
	local all_todos = tm.get_active_todos()
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
		table.insert(lines, tm.format_todo_line(todo, "active"))
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
	local dates = require("todo-manager.dates")

	-- Clear existing due date matches
	vim.cmd([[
		silent! syntax clear TodoDueDatePastDue
		silent! syntax clear TodoDueDateToday
		silent! syntax clear TodoDueDateFuture
	]])

	local current_date = dates.get_current_date()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for _, line in ipairs(lines) do
		local due_date = line:match("%[Due: ([0-9-]+)%]")
		if due_date then
			if dates.is_past_due(due_date) then
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

return M
