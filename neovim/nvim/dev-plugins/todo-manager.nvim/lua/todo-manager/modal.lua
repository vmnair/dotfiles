-- todo-manager/modal.lua
-- Todo create/edit modal dialog

local M = {}

-- Get todo data from current cursor line
function M.get_current_todo()
	local tm = require("todo-manager")
	local line = vim.api.nvim_get_current_line()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	local todo = tm.parse_todo_line(line)
	if not todo then
		return nil
	end

	-- Check if we're in a filtered view (where show dates might be hidden)
	local buf_name = vim.api.nvim_buf_get_name(0)
	if buf_name:match("Active Todos") or buf_name:match("todos") then
		local all_todos = tm.get_all_todos_from_active_file()
		for _, full_todo in ipairs(all_todos) do
			if full_todo.description == todo.description and full_todo.category == todo.category then
				full_todo.line_number = line_num
				return full_todo
			end
		end

		local completed_todos = tm.get_completed_todos()
		for _, full_todo in ipairs(completed_todos) do
			if full_todo.description == todo.description and full_todo.category == todo.category then
				full_todo.line_number = line_num
				return full_todo
			end
		end
	end

	todo.line_number = line_num
	return todo
end

-- Edit todo modal - reuses existing show_todo_modal with pre-populated data
function M.edit_todo_modal()
	local tm = require("todo-manager")
	local current_todo = M.get_current_todo()
	if not current_todo then
		print("Current line is not a todo item")
		return
	end

	local original_line_number = current_todo.line_number
	local original_todo = vim.deepcopy(current_todo)

	tm.show_todo_modal({
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

-- Show interactive todo creation modal
function M.show_todo_modal(options)
	local tm = require("todo-manager")
	options = options or {}

	local default_category = tm.get_current_filter() or "Personal"
	local form_data = {
		description = options.description or "",
		category = options.category or default_category,
		category_index = 3,
		show_date = options.show_date or "",
		due_date = options.due_date or "",
		tags = options.tags or {},
	}

	local categories = tm.config.categories
	for i, cat in ipairs(categories) do
		if cat == form_data.category then
			form_data.category_index = i
			break
		end
	end

	local is_edit_mode = options.mode == "edit"
	local original_line_number = options.line_number
	local original_todo = options.original_todo

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "todomodal")

	local width = 50
	local height = 8

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

	local win = vim.api.nvim_open_win(buf, true, win_opts)

	local function render_form()
		local lines = {}
		table.insert(lines, " Description:  " .. form_data.description)
		table.insert(lines, "")
		table.insert(lines, " Category:    " .. form_data.category)
		table.insert(lines, "")
		table.insert(lines, " Show Date:   " .. (form_data.show_date ~= "" and form_data.show_date or "[Not Set]"))
		table.insert(lines, "")
		table.insert(lines, " Due Date:    " .. (form_data.due_date ~= "" and form_data.due_date or "[Not Set]"))

		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
	end

	local function handle_input()
		vim.keymap.set("n", "i", function()
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			vim.schedule(function()
				local current_line = vim.api.nvim_get_current_line()
				local colon_pos = current_line:find(":")
				if colon_pos then
					local desc_start = current_line:find(":%s*", colon_pos)
					if desc_start then
						local desc_text_start = desc_start + 1
						while desc_text_start <= #current_line and current_line:sub(desc_text_start, desc_text_start) == " " do
							desc_text_start = desc_text_start + 1
						end
						if form_data.description ~= "" then
							vim.api.nvim_win_set_cursor(win, { 1, #current_line })
						else
							vim.api.nvim_win_set_cursor(win, { 1, desc_text_start - 1 })
						end
					else
						vim.api.nvim_win_set_cursor(win, { 1, #current_line })
					end
				end
				vim.cmd("startinsert")
			end)
		end, { buffer = buf, silent = true })

		vim.keymap.set("i", "<ESC>", function()
			local line = vim.api.nvim_get_current_line()
			local desc = line:match(" Description:%s*(.*)") or ""
			desc = desc:gsub("%s+$", "")
			form_data.description = desc
			vim.api.nvim_buf_set_option(buf, "modifiable", false)
			vim.cmd("stopinsert")
			render_form()
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "j", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			if cursor[1] == 3 then
				form_data.category_index = (form_data.category_index % #tm.config.categories) + 1
				form_data.category = tm.config.categories[form_data.category_index]
				render_form()
				vim.api.nvim_win_set_cursor(win, { 3, cursor[2] })
			else
				vim.cmd("normal! j")
			end
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "k", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			if cursor[1] == 3 then
				form_data.category_index = form_data.category_index - 1
				if form_data.category_index < 1 then
					form_data.category_index = #tm.config.categories
				end
				form_data.category = tm.config.categories[form_data.category_index]
				render_form()
				vim.api.nvim_win_set_cursor(win, { 3, cursor[2] })
			else
				vim.cmd("normal! k")
			end
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "<CR>", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local current_line = cursor[1]

			if current_line == 5 then
				tm.get_date_input(function(picked_date)
					if picked_date then
						form_data.show_date = picked_date
						render_form()
					end
				end)
			elseif current_line == 7 then
				tm.get_date_input(function(picked_date)
					if picked_date then
						form_data.due_date = picked_date
						render_form()
					end
				end)
			else
				if form_data.description == "" then
					print("Error: Description is required")
					return
				end

				vim.api.nvim_win_close(win, true)

				if is_edit_mode then
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

					local context = "storage"
					local new_line = tm.format_todo_line(updated_todo, context)

					local current_buf = vim.api.nvim_get_current_buf()
					local was_modifiable = vim.api.nvim_buf_get_option(current_buf, "modifiable")
					if not was_modifiable then
						vim.api.nvim_buf_set_option(current_buf, "modifiable", true)
						vim.api.nvim_buf_set_option(current_buf, "readonly", false)
					end

					vim.api.nvim_buf_set_lines(0, original_line_number - 1, original_line_number, false, { new_line })

					if not was_modifiable then
						vim.api.nvim_buf_set_option(current_buf, "modifiable", false)
						vim.api.nvim_buf_set_option(current_buf, "readonly", true)
					end

					local current_file = vim.api.nvim_buf_get_name(0)
					local active_file_path = tm.config.todo_dir .. "/" .. tm.config.active_file
					local completed_file_path = tm.config.todo_dir .. "/" .. tm.config.completed_file

					if current_file == active_file_path or current_file == completed_file_path then
						vim.cmd("write")
					end

					tm.refresh_filtered_view_if_open()
					print("✓ Todo updated: " .. form_data.description)
				else
					local success = tm.add_todo(
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

		vim.keymap.set("n", "<ESC>", function()
			vim.api.nvim_win_close(win, true)
			print("Todo creation cancelled")
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, true)
			print("Todo creation cancelled")
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "s", function()
			if form_data.description == "" then
				print("Error: Description is required")
				return
			end

			vim.api.nvim_win_close(win, true)

			if is_edit_mode then
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

				local context = "storage"
				local new_line = tm.format_todo_line(updated_todo, context)

				local all_todos = tm.get_all_todos_from_active_file()
				local found = false
				for i, file_todo in ipairs(all_todos) do
					if
						file_todo.description == original_todo.description
						and file_todo.category == original_todo.category
						and file_todo.added_date == original_todo.added_date
					then
						all_todos[i] = updated_todo
						found = true
						break
					end
				end

				if found then
					local active_header = "# Active Todos (Raw)\n\nManaged by Vinod's Todo Manager"
					tm.write_todos_to_file(tm.config.active_file, all_todos, active_header, "storage")
					tm.refresh_filtered_view_if_open()
				else
					print("⚠ Could not find todo to update in file")
				end

				print("✓ Todo updated: " .. form_data.description)
			else
				local success = tm.add_todo(
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

		vim.keymap.set("n", "<Tab>", function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local current_line = cursor[1]

			if current_line <= 1 then
				vim.api.nvim_win_set_cursor(win, { 3, 14 })
			elseif current_line <= 3 then
				vim.api.nvim_win_set_cursor(win, { 5, 14 })
			elseif current_line <= 5 then
				vim.api.nvim_win_set_cursor(win, { 7, 14 })
			else
				local desc_len = #form_data.description
				vim.api.nvim_win_set_cursor(win, { 1, 15 + desc_len })
			end
		end, { buffer = buf, silent = true })
	end

	handle_input()
	render_form()

	if is_edit_mode and form_data.description ~= "" then
		vim.schedule(function()
			vim.cmd("normal! 0")
			vim.cmd("normal! f:")
			vim.cmd("normal! 2l")
			vim.cmd("normal! E")
		end)
	end
end

return M
