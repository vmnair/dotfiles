-- todo-manager/zk.lua
-- ZK note integration and todo ID generation

local M = {}

-- Get all folders in notebook directory recursively for note placement
local function get_notebook_folders()
	local config = require("todo-manager").config
	local notebook_dir = config.notebook_dir
	local folders = {}

	local result = vim.fn.system({ "find", notebook_dir, "-maxdepth", "1", "-type", "d" })
	if vim.v.shell_error ~= 0 or not result or result == "" then
		return { "todo" }
	end

	for line in result:gmatch("[^\n]+") do
		local relative = line:sub(#notebook_dir + 2)
		if relative and relative ~= "" then
			if not relative:match("^%.") and not relative:match("/%.") then
				table.insert(folders, relative)
			end
		end
	end

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
	local added_date = todo.added_date
	if not added_date or added_date == "" then
		added_date = os.date("%m-%d-%Y")
	end

	local base_string = (todo.description or "") .. "|" .. (todo.category or "Personal") .. "|" .. added_date
	local hash = 0
	for i = 1, #base_string do
		hash = (hash * 31 + string.byte(base_string, i)) % 1000000
	end
	return "todo_" .. hash
end

-- Create or open zk note from current todo with smart detection
function M.create_or_open_note_from_todo()
	local tm = require("todo-manager")
	local current_todo = tm.get_current_todo()
	if not current_todo then
		print("Current line is not a todo item")
		return
	end

	local todo_cursor_line = vim.fn.line(".")
	local todo_cursor_col = vim.fn.col(".")

	if vim.fn.executable("zk") ~= 1 then
		print("✗ zk command not found. Please install zk: brew install zk")
		return
	end

	local note_title = current_todo.description
	local todo_id = generate_todo_id(current_todo)

	local search_result = vim.fn.system({
		"grep", "-r", "-F", "-l", "todo_id: " .. todo_id,
		"--include=*.md", tm.config.notebook_dir,
	})

	if vim.v.shell_error == 0 and search_result and search_result ~= "" then
		local full_path = vim.trim(search_result:match("([^\n]+)") or "")
		if full_path ~= "" then
			print("📖 Opening existing note: " .. vim.fn.fnamemodify(full_path, ":t"))
			vim.cmd("edit " .. vim.fn.fnameescape(full_path))

			local todo_file = tm.config.todo_dir .. "/" .. tm.config.active_file
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

			vim.schedule(function()
				local buf = vim.api.nvim_get_current_buf()
				local total_lines = vim.api.nvim_buf_line_count(buf)
				local all_lines = vim.api.nvim_buf_get_lines(buf, 0, total_lines, false)

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

				local insert_line = total_lines
				for i = notes_line + 1, total_lines do
					if all_lines[i] and all_lines[i]:match("^%s*%-%-%-+%s*$") then
						insert_line = i - 1
						break
					end
				end

				local today = os.date("%m/%d/%Y")
				local last_date_found = nil
				for i = insert_line, notes_line + 1, -1 do
					local date_match = all_lines[i] and all_lines[i]:match("^(%d%d/%d%d/%d%d%d%d)%s*$")
					if date_match then
						last_date_found = date_match
						break
					end
				end

				if last_date_found ~= today then
					vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, { "", today, "" })
					vim.fn.cursor(insert_line + 3, 1)
				else
					vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, { "" })
					vim.fn.cursor(insert_line + 1, 1)
				end
				vim.cmd("startinsert")

				vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
					buffer = 0,
					callback = function()
						if vim.bo.modified then
							vim.cmd("silent! write")
						end
					end,
				})

				vim.api.nvim_create_autocmd({ "BufWritePost", "WinClosed", "BufDelete" }, {
					buffer = 0,
					once = true,
					callback = function()
						vim.schedule(function()
							local todo_file_path = tm.config.todo_dir .. "/" .. tm.config.active_file
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

	if current_todo.has_note then
		vim.notify("⚠ Note indicator (󰈙) found but no linked note exists. Creating new note.", vim.log.levels.WARN)
	end

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

		local canonical_path = vim.fn.fnamemodify(note_path, ":p")
		local canonical_notebook = vim.fn.fnamemodify(tm.config.notebook_dir, ":p")
		if not vim.startswith(canonical_path, canonical_notebook) then
			print("✗ Note path outside notebook directory: " .. note_path)
			return
		end

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
		table.insert(note_content, tm.format_todo_line(current_todo, "storage"))
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
				vim.fn.cursor(notes_line + 3, 1)
				vim.cmd("startinsert")
			else
				vim.fn.cursor(total_lines, 1)
				vim.cmd("startinsert")
			end

			vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
				buffer = 0,
				callback = function()
					if vim.bo.modified then
						vim.cmd("silent! write")
					end
				end,
			})

			vim.api.nvim_create_autocmd("BufWritePost", {
				buffer = 0,
				once = true,
				callback = function()
					local todo_file_inner = tm.config.todo_dir .. "/" .. tm.config.active_file
					if vim.fn.filereadable(todo_file_inner) == 1 then
						vim.defer_fn(function()
							vim.cmd("edit " .. vim.fn.fnameescape(todo_file_inner))
							pcall(vim.fn.cursor, todo_cursor_line, todo_cursor_col)
						end, 100)
					end
				end,
			})
		end)

		print("✓ Created note in '" .. selected_folder .. "': " .. note_title)

		vim.schedule(function()
			local todo_file = tm.config.todo_dir .. "/" .. tm.config.active_file
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

-- Expose for testing
M._test = {
	generate_todo_id = generate_todo_id,
}

return M
