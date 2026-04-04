-- todo-manager/continuation.lua
-- Command continuation workflow state machine

local M = {}

-- State for command-line continuation workflows
M._continuation_state = {
	active = false,
	description = "",
	category = "",
	tags = "",
	due_date = "",
	show_date = "",
	waiting_for = nil,
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
	local dates = require("todo-manager.dates")
	local is_scheduled = not dates.is_show_date_reached(state.show_date)
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
	local tm = require("todo-manager")

	if not state.active then
		return
	end

	-- Reset state
	M._continuation_state.active = false

	local command_type, is_valid = parse_continuation_input(input, context.expected_command)

	if command_type == "finish" then
		local success = tm.add_todo(state.description, state.category, state.tags, state.due_date, state.show_date)
		if success then
			print(format_todo_success_message(state))
		else
			print("✗ Failed to add todo")
		end
	elseif command_type == context.expected_command then
		tm.get_date_input(function(picked_date)
			if picked_date then
				state[context.date_field] = picked_date
			else
				print("No " .. context.expected_command .. " date selected, keeping current dates")
			end

			local success = tm.add_todo(state.description, state.category, state.tags, state.due_date, state.show_date)
			if success then
				print(format_todo_success_message(state))
			else
				print("✗ Failed to add todo")
			end
		end)
	else
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

-- Expose for testing
M._test = {
	parse_continuation_input = parse_continuation_input,
	format_todo_success_message = format_todo_success_message,
}

return M
