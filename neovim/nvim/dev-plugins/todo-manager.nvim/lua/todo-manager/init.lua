-- todo-manager/init.lua
-- Main module: config, public API re-exports to submodules
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
-- DELEGATIONS: dates module
-- ========================================

-- Global functions (referenced as bare globals by other code in this file and tests)
function is_past_due(date_str)
	return require("todo-manager.dates").is_past_due(date_str)
end

function is_due_today(date_str)
	return require("todo-manager.dates").is_due_today(date_str)
end

function M.resolve_date_shortcut(keyword)
	return require("todo-manager.dates").resolve_date_shortcut(keyword)
end

-- ========================================
-- DELEGATIONS: parser module
-- ========================================

function M.parse_todo_line(line)
	return require("todo-manager.parser").parse_todo_line(line)
end

function M.format_todo_line(todo, context)
	return require("todo-manager.parser").format_todo_line(todo, context)
end

-- ========================================
-- DELEGATIONS: storage module
-- ========================================

function M.get_active_todos()
	return require("todo-manager.storage").get_active_todos()
end

function M.get_completed_todos()
	return require("todo-manager.storage").get_completed_todos()
end

function M.get_all_todos_from_active_file()
	return require("todo-manager.storage").get_all_todos_from_active_file()
end

function M.get_scheduled_todos()
	return require("todo-manager.storage").get_scheduled_todos()
end

function M.get_upcoming_todos(days)
	return require("todo-manager.storage").get_upcoming_todos(days)
end

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

-- ========================================
-- DELEGATIONS: categories module
-- ========================================

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
-- DELEGATIONS: ui module
-- ========================================

function M.toggle_todo_on_line()
	return require("todo-manager.ui").toggle_todo_on_line()
end

function M.list_active_todos(category)
	return require("todo-manager.ui").list_active_todos(category)
end

function M.toggle_todo_in_filtered_view()
	return require("todo-manager.ui").toggle_todo_in_filtered_view()
end

function M.open_filtered_active_view()
	return require("todo-manager.ui").open_filtered_active_view()
end

function M.setup_todo_buffer_keybindings(buf)
	return require("todo-manager.ui").setup_todo_buffer_keybindings(buf)
end

function M.display_todos(todos, title)
	return require("todo-manager.ui").display_todos(todos, title)
end

function M.apply_category_filter_to_current_view()
	return require("todo-manager.ui").apply_category_filter_to_current_view()
end

function M.refresh_filtered_view_with_state()
	return require("todo-manager.ui").refresh_filtered_view_with_state()
end

function M.refresh_filtered_view_if_open()
	return require("todo-manager.ui").refresh_filtered_view_if_open()
end

function M.setup_todo_syntax()
	return require("todo-manager.ui").setup_todo_syntax()
end

function M.highlight_due_dates_with_colors()
	return require("todo-manager.ui").highlight_due_dates_with_colors()
end

-- ========================================
-- DELEGATIONS: calendar module
-- ========================================

function M.show_date_picker(callback)
	return require("todo-manager.calendar").show_date_picker(callback)
end

function M.get_date_input(callback)
	return require("todo-manager.calendar").get_date_input(callback)
end

function M.get_date_with_action(options)
	return require("todo-manager.calendar").get_date_with_action(options)
end

function M.update_form_field_with_date(field_name, form_data, refresh_callback)
	return require("todo-manager.calendar").update_form_field_with_date(field_name, form_data, refresh_callback)
end

function M.create_todo_with_date(todo_params, date_field, completion_callback)
	return require("todo-manager.calendar").create_todo_with_date(todo_params, date_field, completion_callback)
end

function M.handle_command_continuation(description, category, tags, due_date, show_date, use_show_calendar, use_due_calendar, command_prefix)
	return require("todo-manager.calendar").handle_command_continuation(description, category, tags, due_date, show_date, use_show_calendar, use_due_calendar, command_prefix)
end

-- ========================================
-- DELEGATIONS: modal module
-- ========================================

function M.show_todo_modal(options)
	return require("todo-manager.modal").show_todo_modal(options)
end

function M.get_current_todo()
	return require("todo-manager.modal").get_current_todo()
end

function M.edit_todo_modal()
	return require("todo-manager.modal").edit_todo_modal()
end

-- ========================================
-- DELEGATIONS: continuation module
-- ========================================

-- Expose continuation state for todo_commands.lua access
M._continuation_state = require("todo-manager.continuation")._continuation_state

function M.process_continuation_workflow(input, context)
	return require("todo-manager.continuation").process_continuation_workflow(input, context)
end

function M.process_continuation(input)
	return require("todo-manager.continuation").process_continuation(input)
end

function M.process_show_continuation(input)
	return require("todo-manager.continuation").process_show_continuation(input)
end

-- ========================================
-- DELEGATIONS: zk module
-- ========================================

function M.create_or_open_note_from_todo()
	return require("todo-manager.zk").create_or_open_note_from_todo()
end

-- ========================================
-- TEST EXPORTS
-- ========================================

M._test = {
	generate_todo_id = function(...)
		return require("todo-manager.zk")._test.generate_todo_id(...)
	end,
	is_show_date_reached = function(...)
		return require("todo-manager.dates").is_show_date_reached(...)
	end,
}

return M
