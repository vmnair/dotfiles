-- tests/parser_spec.lua
-- Tests for parse_todo_line, format_todo_line, and round-trips
-- Run: cd dev-plugins/todo-manager.nvim && nvim --headless -l tests/parser_spec.lua

local h = dofile("tests/helpers.lua")
local M = h.load_module()
local describe, test = h.describe, h.test
local assert_eq, assert_true, assert_false = h.assert_eq, h.assert_true, h.assert_false
local assert_nil, assert_not_nil, assert_table_len = h.assert_nil, h.assert_not_nil, h.assert_table_len

-- ========================================
-- Tests: parse_todo_line
-- ========================================
describe("parse_todo_line", function()
	test("simple uncompleted todo", function()
		local todo = M.parse_todo_line("- [ ] 󰿷 Take medicine")
		assert_not_nil(todo)
		assert_eq(todo.completed, false)
		assert_eq(todo.description, "Take medicine")
		assert_eq(todo.category, "Medicine")
	end)

	test("completed todo with tags", function()
		local todo = M.parse_todo_line("- [x] 󰇄 Fix server #urgent #devops (03-10-2026)")
		assert_not_nil(todo)
		assert_true(todo.completed)
		assert_eq(todo.category, "OMS")
		assert_eq(todo.description, "Fix server")
		assert_table_len(todo.tags, 2)
		assert_eq(todo.tags[1], "urgent")
		assert_eq(todo.tags[2], "devops")
		assert_eq(todo.added_date, "03-10-2026")
	end)

	test("todo with show_date and due_date", function()
		local todo = M.parse_todo_line("- [ ]  Buy groceries [Show: 03-20-2026] [Due: 03-25-2026] (03-15-2026)")
		assert_not_nil(todo)
		assert_eq(todo.show_date, "03-20-2026")
		assert_eq(todo.due_date, "03-25-2026")
		assert_eq(todo.added_date, "03-15-2026")
		assert_eq(todo.description, "Buy groceries")
		assert_eq(todo.category, "Personal")
	end)

	test("todo with note indicator", function()
		local todo = M.parse_todo_line("- [ ] 󰿷 Take medicine #health (03-10-2026) 󰈙")
		assert_not_nil(todo)
		assert_true(todo.has_note)
		assert_eq(todo.description, "Take medicine")
		assert_eq(todo.tags[1], "health")
	end)

	test("multiple tags", function()
		local todo = M.parse_todo_line("- [ ]  Task #alpha #beta #gamma")
		assert_not_nil(todo)
		assert_table_len(todo.tags, 3)
		assert_eq(todo.tags[1], "alpha")
		assert_eq(todo.tags[3], "gamma")
	end)

	test("nil input returns nil", function()
		assert_nil(M.parse_todo_line(nil))
	end)

	test("empty string returns nil", function()
		assert_nil(M.parse_todo_line(""))
	end)

	test("non-todo line returns nil", function()
		assert_nil(M.parse_todo_line("Just a regular line"))
	end)

	test("description with special characters", function()
		local todo = M.parse_todo_line("- [ ]  Call Dr. Smith & schedule appt (03-10-2026)")
		assert_not_nil(todo)
		assert_eq(todo.description, "Call Dr. Smith & schedule appt")
	end)

	test("todo with no added_date", function()
		local todo = M.parse_todo_line("- [ ]  Simple task")
		assert_not_nil(todo)
		assert_eq(todo.added_date, "")
		assert_eq(todo.description, "Simple task")
	end)

	test("default Personal category when no icon match", function()
		local todo = M.parse_todo_line("- [ ] Unknown icon task")
		assert_not_nil(todo)
		assert_eq(todo.category, "Personal")
	end)
end)

-- ========================================
-- Tests: format_todo_line
-- ========================================
describe("format_todo_line", function()
	test("storage context: full format with all fields", function()
		local todo = {
			completed = false,
			description = "Take medicine",
			category = "Medicine",
			tags = { "health" },
			due_date = "03-25-2026",
			show_date = "03-20-2026",
			added_date = "03-15-2026",
			has_note = true,
		}
		local line = M.format_todo_line(todo, "storage")
		assert_true(line:find("- [ ]", 1, true) ~= nil, "has checkbox")
		assert_true(line:find("󰿷", 1, true) ~= nil, "has Medicine icon")
		assert_true(line:find("Take medicine", 1, true) ~= nil, "has description")
		assert_true(line:find("[Show: 03-20-2026]", 1, true) ~= nil, "has show_date")
		assert_true(line:find("[Due: 03-25-2026]", 1, true) ~= nil, "has due_date")
		assert_true(line:find("#health", 1, true) ~= nil, "has tag")
		assert_true(line:find("(03-15-2026)", 1, true) ~= nil, "has added_date")
		assert_true(line:find("󰈙", 1, true) ~= nil, "has note indicator")
	end)

	test("active context: omits show_date and added_date", function()
		local todo = {
			completed = false,
			description = "Task",
			category = "Personal",
			tags = {},
			due_date = "03-25-2026",
			show_date = "03-20-2026",
			added_date = "03-15-2026",
			has_note = false,
		}
		local line = M.format_todo_line(todo, "active")
		assert_nil(line:find("[Show:", 1, true), "no show_date in active")
		assert_nil(line:find("(03-15-2026)", 1, true), "no added_date in active")
		assert_true(line:find("[Due: 03-25-2026]", 1, true) ~= nil, "has due_date")
	end)

	test("scheduled context: includes show_date", function()
		local todo = {
			completed = false,
			description = "Future task",
			category = "OMS",
			tags = {},
			due_date = "",
			show_date = "04-01-2026",
			added_date = "03-15-2026",
			has_note = false,
		}
		local line = M.format_todo_line(todo, "scheduled")
		assert_true(line:find("[Show: 04-01-2026]", 1, true) ~= nil, "has show_date")
	end)

	test("completed checkbox", function()
		local todo = {
			completed = true,
			description = "Done task",
			category = "Personal",
			tags = {},
			due_date = "",
			show_date = "",
			added_date = "",
			has_note = false,
		}
		local line = M.format_todo_line(todo, "storage")
		assert_true(line:find("- [x]", 1, true) ~= nil, "has completed checkbox")
	end)
end)

-- ========================================
-- Tests: parse → format round-trip
-- ========================================
describe("parse → format round-trip", function()
	local icons = M.config.category_icons

	test("full todo round-trips losslessly in storage context", function()
		local original = "- [ ] " .. icons.Medicine .. " Take medicine [Show: 03-20-2026] [Due: 03-25-2026] #health (03-15-2026)"
		local todo = M.parse_todo_line(original)
		assert_not_nil(todo)
		local formatted = M.format_todo_line(todo, "storage")
		assert_eq(formatted, original)
	end)

	test("minimal todo round-trips", function()
		local original = "- [ ] " .. icons.Personal .. " Simple task"
		local todo = M.parse_todo_line(original)
		local formatted = M.format_todo_line(todo, "storage")
		assert_eq(formatted, original)
	end)

	test("completed todo round-trips", function()
		local original = "- [x] " .. icons.OMS .. " Done task #work (03-10-2026)"
		local todo = M.parse_todo_line(original)
		local formatted = M.format_todo_line(todo, "storage")
		assert_eq(formatted, original)
	end)

	test("todo with note indicator round-trips", function()
		local original = "- [ ] " .. icons.Medicine .. " Take medicine #health (03-10-2026) 󰈙"
		local todo = M.parse_todo_line(original)
		local formatted = M.format_todo_line(todo, "storage")
		assert_eq(formatted, original)
	end)
end)

h.summary()
