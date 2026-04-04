-- todo-manager/storage.lua
-- File I/O for reading/writing todos, initialization, and todo retrieval

local M = {}

-- Get full file path for todo files
local function get_file_path(filename)
	return require("todo-manager").config.todo_dir .. "/" .. filename
end

-- Read todos from file
function M.read_todos_from_file(filename)
	local file_path = get_file_path(filename)
	local file = io.open(file_path, "r")
	if not file then
		return {}
	end
	local parser = require("todo-manager.parser")
	local todos = {}
	for line in file:lines() do
		local todo = parser.parse_todo_line(line)
		if todo then
			table.insert(todos, todo)
		end
	end
	file:close()
	return todos
end

-- Write todos to file with header
function M.write_todos_to_file(filename, todos, header, context)
	local file_path = get_file_path(filename)
	local file = io.open(file_path, "w")
	if not file then
		error("Could not open file for writing: " .. file_path)
		return false
	end
	local parser = require("todo-manager.parser")
	-- Write header if provided
	if header then
		file:write(header .. "\n\n")
	end
	-- Write each todo
	for _, todo in ipairs(todos) do
		file:write(parser.format_todo_line(todo, context) .. "\n")
	end
	file:close()
	return true
end

-- Initialize todo system
function M.init_todo_files()
	local config = require("todo-manager").config

	-- Create todo directory if it doesn't exist
	local todo_dir = config.todo_dir
	local stat = vim.loop.fs_stat(todo_dir)
	if not stat then
		vim.loop.fs_mkdir(todo_dir, 448) -- 0700 in octal
	end

	-- Initialize active todos file
	local active_file_path = get_file_path(config.active_file)
	local active_file = io.open(active_file_path, "r")
	if not active_file then
		active_file = io.open(active_file_path, "w")
		if active_file then
			active_file:write("# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager\n\n")
			active_file:close()
		end
	else
		active_file:close()
	end

	-- Initialize completed todos file
	local completed_file_path = get_file_path(config.completed_file)
	local completed_file = io.open(completed_file_path, "r")
	if not completed_file then
		completed_file = io.open(completed_file_path, "w")
		if completed_file then
			completed_file:write("# Completed Todos\n\nArchive of completed todos\n\n")
			completed_file:close()
		end
	else
		completed_file:close()
	end

	return true
end

-- Add todo function
function M.add_todo(description, category, tags, due_date, show_date)
	if not description or description == "" then
		return false
	end

	local tm = require("todo-manager")
	local dates = require("todo-manager.dates")

	-- Initialize files if needed
	M.init_todo_files()

	-- Create todo object
	local todo = {
		completed = false,
		description = description,
		category = category or "Personal",
		tags = tags or {},
		due_date = due_date or "",
		show_date = show_date or "",
		added_date = dates.get_current_date(),
		completion_date = "",
	}

	-- Read existing todos
	local todos = M.read_todos_from_file(tm.config.active_file)

	-- Add new todo
	table.insert(todos, todo)

	-- Write back to file
	local header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
	local success = M.write_todos_to_file(tm.config.active_file, todos, header, "storage")

	-- Refresh filtered view if it's open
	if success then
		tm.refresh_filtered_view_if_open()
	end

	return success
end

-- Get active todos (filtered by show_date reached)
function M.get_active_todos()
	local config = require("todo-manager").config
	local dates = require("todo-manager.dates")
	local all_todos = M.read_todos_from_file(config.active_file)
	local active_todos = {}

	-- Only return todos that are not completed AND have reached their show date
	for _, todo in ipairs(all_todos) do
		if not todo.completed and dates.is_show_date_reached(todo.show_date) then
			table.insert(active_todos, todo)
		end
	end

	return active_todos
end

-- Get completed todos
function M.get_completed_todos()
	local config = require("todo-manager").config
	return M.read_todos_from_file(config.completed_file)
end

-- Get all todos from active file (including scheduled)
function M.get_all_todos_from_active_file()
	local config = require("todo-manager").config
	local all_todos = M.read_todos_from_file(config.active_file)
	local active_todos = {}

	for _, todo in ipairs(all_todos) do
		if not todo.completed then
			table.insert(active_todos, todo)
		end
	end

	return active_todos
end

-- Get scheduled todos (future show dates)
function M.get_scheduled_todos()
	local config = require("todo-manager").config
	local dates = require("todo-manager.dates")
	local all_todos = M.read_todos_from_file(config.active_file)
	local scheduled_todos = {}

	for _, todo in ipairs(all_todos) do
		if not todo.completed and not dates.is_show_date_reached(todo.show_date) then
			table.insert(scheduled_todos, todo)
		end
	end

	return scheduled_todos
end

-- Get upcoming todos (within specified number of days)
function M.get_upcoming_todos(days)
	days = days or 7
	local config = require("todo-manager").config
	local all_todos = M.read_todos_from_file(config.active_file)
	local upcoming_todos = {}
	local current_time = os.time()
	local future_cutoff = current_time + (days * 24 * 60 * 60)

	for _, todo in ipairs(all_todos) do
		if not todo.completed and todo.show_date and todo.show_date ~= "" then
			-- Parse the show date
			local month, day_num, year = todo.show_date:match("(%d+)-(%d+)-(%d+)")
			if month and day_num and year then
				local show_time = os.time({
					year = tonumber(year) --[[@as integer]],
					month = tonumber(month) --[[@as integer]],
					day = tonumber(day_num) --[[@as integer]],
					hour = 0,
					min = 0,
					sec = 0,
				})

				-- Include if within the upcoming period (from now to future cutoff)
				if show_time >= current_time and show_time <= future_cutoff then
					table.insert(upcoming_todos, todo)
				end
			end
		end
	end

	return upcoming_todos
end

return M
