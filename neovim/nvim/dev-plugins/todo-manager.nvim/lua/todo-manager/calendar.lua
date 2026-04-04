-- todo-manager/calendar.lua
-- Date picker floating window and date utilities

local M = {}

-- Consolidated date picker utility function
function M.get_date_with_action(options)
	local dates = require("todo-manager.dates")
	-- Default options
	local opts = vim.tbl_extend("force", {
		on_success = nil,
		on_cancel = nil,
		fallback_date = "none",
		cancel_message = nil,
		success_message = nil,
		auto_fallback = false,
	}, options or {})

	if not opts.on_success or type(opts.on_success) ~= "function" then
		error("get_date_with_action: on_success callback is required")
		return
	end

	M.get_date_input(function(picked_date)
		if picked_date then
			if opts.success_message then
				print(string.format(opts.success_message, picked_date))
			end
			opts.on_success(picked_date)
		else
			if opts.cancel_message then
				print(opts.cancel_message)
			end

			local fallback_value = nil
			if opts.fallback_date == "today" then
				fallback_value = dates.get_current_date()
				print("No date selected, using today's date: " .. fallback_value)
			elseif opts.fallback_date ~= "none" and type(opts.fallback_date) == "string" then
				fallback_value = opts.fallback_date
				print("No date selected, using fallback: " .. fallback_value)
			end

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
			local tm = require("todo-manager")
			local success = tm.add_todo(
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

-- Show interactive calendar date picker
function M.show_date_picker(callback)
	local current_date = os.date("*t")
	local selected_year = current_date.year
	local selected_month = current_date.month
	local selected_day = current_date.day
	local today = { year = current_date.year, month = current_date.month, day = current_date.day }

	local month_names = {
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December",
	}

	local function days_in_month(month, year)
		local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
		if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)) then
			return 29
		end
		return days[month]
	end

	local function first_day_of_month(month, year)
		local first_date = os.time({ year = year, month = month, day = 1 })
		return tonumber(os.date("%w", first_date))
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "filetype", "calendar")

	local function render_calendar()
		local lines = {}

		local header = month_names[selected_month] .. " " .. selected_year
		table.insert(lines, " " .. string.rep(" ", math.floor((20 - #header) / 2)) .. header)
		table.insert(lines, " Su Mo Tu We Th Fr Sa")

		local max_days = days_in_month(selected_month, selected_year)
		local first_day = first_day_of_month(selected_month, selected_year)

		local current_line = " "

		for i = 1, first_day do
			current_line = current_line .. "   "
		end

		for day = 1, max_days do
			local day_str = string.format("%2d", day)

			if selected_year == today.year and selected_month == today.month and day == today.day then
				day_str = "[" .. string.format("%d", day) .. "]"
				if day < 10 then
					day_str = "[" .. day .. "]"
				end
			end

			if day == selected_day then
				if day_str:match("%[") then
					day_str = day_str
				else
					day_str = "*" .. string.format("%d", day) .. "*"
					if day < 10 then
						day_str = "*" .. day .. "*"
					end
				end
			end

			current_line = current_line .. day_str .. " "

			if (first_day + day - 1) % 7 == 6 then
				table.insert(lines, current_line)
				current_line = " "
			end
		end

		if current_line ~= " " then
			table.insert(lines, current_line)
		end

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

	render_calendar()

	local function setup_keymaps()
		vim.keymap.set("n", "h", function()
			selected_month = selected_month - 1
			if selected_month < 1 then
				selected_month = 12
				selected_year = selected_year - 1
			end
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
			local max_days = days_in_month(selected_month, selected_year)
			if selected_day > max_days then
				selected_day = max_days
			end
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			render_calendar()
		end, { buffer = buf, silent = true })

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

		vim.keymap.set("n", "H", function()
			selected_year = selected_year - 1
			local max_days = days_in_month(selected_month, selected_year)
			if selected_day > max_days then
				selected_day = max_days
			end
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			render_calendar()
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "L", function()
			selected_year = selected_year + 1
			local max_days = days_in_month(selected_month, selected_year)
			if selected_day > max_days then
				selected_day = max_days
			end
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			render_calendar()
		end, { buffer = buf, silent = true })

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
		return false
	end

	if use_show_calendar or use_due_calendar then
		local function add_todo_with_dates()
			local tm = require("todo-manager")
			local success = tm.add_todo(description, category, tags, due_date, show_date)
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
						due_date = os.date("%m-%d-%Y")
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
						show_date = os.date("%m-%d-%Y")
						print("No show date selected, using today's date: " .. show_date)
					end
					handle_due_date_picker()
				end)
			else
				handle_due_date_picker()
			end
		end

		handle_show_date_picker()
		return true
	end

	return false
end

return M
