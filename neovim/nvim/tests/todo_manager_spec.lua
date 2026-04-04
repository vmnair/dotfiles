-- Todo Manager Test Suite
-- Run: cd neovim/nvim && nvim --headless -l tests/todo_manager_spec.lua

-- ========================================
-- Mini Test Framework
-- ========================================
local passed, failed, errors = 0, 0, {}
local current_group = ""

local function describe(name, fn)
	current_group = name
	print("\n" .. name)
	fn()
end

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		print("  ✓ " .. name)
	else
		failed = failed + 1
		table.insert(errors, current_group .. " > " .. name .. ": " .. tostring(err))
		print("  ✗ " .. name .. " — " .. tostring(err))
	end
end

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "") .. " expected: " .. tostring(expected) .. ", got: " .. tostring(actual))
	end
end

local function assert_true(val, msg)
	if not val then error((msg or "") .. " expected true, got: " .. tostring(val)) end
end

local function assert_false(val, msg)
	if val then error((msg or "") .. " expected false, got: " .. tostring(val)) end
end

local function assert_nil(val, msg)
	if val ~= nil then error((msg or "") .. " expected nil, got: " .. tostring(val)) end
end

local function assert_not_nil(val, msg)
	if val == nil then error((msg or "") .. " expected non-nil") end
end

local function assert_table_len(tbl, len, msg)
	assert_eq(#tbl, len, (msg or "") .. " table length")
end

local function summary()
	print("\n" .. string.rep("=", 40))
	print(string.format("Results: %d passed, %d failed, %d total", passed, failed, passed + failed))
	if #errors > 0 then
		print("\nFailures:")
		for _, e in ipairs(errors) do
			print("  • " .. e)
		end
	end
	print(string.rep("=", 40))
	os.exit(failed > 0 and 1 or 0)
end

-- ========================================
-- Module Loading
-- ========================================
-- Stub vim globals that todo_manager.lua references at load time
_G.vim = _G.vim or {
	fn = { expand = function(s) return s end, stdpath = function() return "/tmp" end },
	opt = {},
	g = {},
	keymap = { set = function() end },
	api = {
		nvim_create_user_command = function() end,
		nvim_create_autocmd = function() end,
		nvim_create_augroup = function() return 0 end,
		nvim_buf_set_keymap = function() end,
		nvim_set_hl = function() end,
		nvim_buf_get_name = function() return "" end,
		nvim_buf_get_lines = function() return {} end,
		nvim_buf_set_lines = function() end,
		nvim_buf_line_count = function() return 0 end,
		nvim_win_get_cursor = function() return { 1, 0 } end,
		nvim_win_set_cursor = function() end,
		nvim_get_current_buf = function() return 0 end,
		nvim_open_win = function() return 0 end,
		nvim_create_buf = function() return 0 end,
		nvim_win_close = function() end,
		nvim_win_get_width = function() return 80 end,
		nvim_win_get_height = function() return 24 end,
		nvim_buf_set_option = function() end,
		nvim_win_set_option = function() end,
		nvim_buf_get_option = function() return "" end,
		nvim_set_option_value = function() end,
	},
	cmd = function() end,
	schedule = function(fn) fn() end,
	notify = function() end,
	tbl_deep_extend = function(_, t1, t2)
		local result = {}
		for k, v in pairs(t1 or {}) do result[k] = v end
		for k, v in pairs(t2 or {}) do result[k] = v end
		return result
	end,
	ui = { select = function() end, input = function() end },
	loop = { fs_stat = function() return nil end },
}

package.path = "lua/?.lua;lua/?/init.lua;dev-plugins/todo-manager.nvim/lua/?.lua;dev-plugins/todo-manager.nvim/lua/?/init.lua;" .. package.path

local ok, M = pcall(require, "todo-manager")
if not ok then
	print("ERROR: Failed to load todo-manager: " .. tostring(M))
	os.exit(1)
end

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
end)

-- ========================================
-- Tests: parse → format round-trip
-- ========================================
describe("parse → format round-trip", function()
	-- Build test lines using the actual config icons to avoid multi-byte encoding mismatches
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

-- ========================================
-- Tests: validate_category
-- ========================================
describe("validate_category", function()
	test("exact match case-insensitive", function()
		local ok, result = M.validate_category("medicine")
		assert_true(ok)
		assert_eq(result, "Medicine")
	end)

	test("exact match uppercase", function()
		local ok, result = M.validate_category("OMS")
		assert_true(ok)
		assert_eq(result, "OMS")
	end)

	test("empty rejection", function()
		local ok, msg = M.validate_category("")
		assert_false(ok)
		assert_true(msg:find("empty") ~= nil)
	end)

	test("nil rejection", function()
		local ok, msg = M.validate_category(nil)
		assert_false(ok)
		assert_true(msg:find("empty") ~= nil)
	end)

	test("fuzzy suggestion for partial match", function()
		local ok, msg = M.validate_category("med")
		assert_false(ok)
		assert_true(msg:find("Did you mean") ~= nil)
		assert_true(msg:find("Medicine") ~= nil)
	end)

	test("available list for no match", function()
		local ok, msg = M.validate_category("zzz")
		assert_false(ok)
		assert_true(msg:find("Available") ~= nil)
	end)
end)

-- ========================================
-- Tests: Date functions
-- ========================================
describe("is_past_due", function()
	test("nil returns false", function()
		assert_false(is_past_due(nil))
	end)

	test("empty string returns false", function()
		assert_false(is_past_due(""))
	end)

	test("yesterday is past due", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_true(is_past_due(yesterday))
	end)

	test("today is not past due", function()
		local today = os.date("%m-%d-%Y")
		assert_false(is_past_due(today))
	end)

	test("tomorrow is not past due", function()
		local tomorrow = os.date("%m-%d-%Y", os.time() + 86400)
		assert_false(is_past_due(tomorrow))
	end)

	test("invalid date string returns false", function()
		assert_false(is_past_due("not-a-date"))
	end)
end)

describe("is_due_today", function()
	test("nil returns false", function()
		assert_false(is_due_today(nil))
	end)

	test("empty returns false", function()
		assert_false(is_due_today(""))
	end)

	test("today returns true", function()
		local today = os.date("%m-%d-%Y")
		assert_true(is_due_today(today))
	end)

	test("yesterday returns false", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_false(is_due_today(yesterday))
	end)

	test("tomorrow returns false", function()
		local tomorrow = os.date("%m-%d-%Y", os.time() + 86400)
		assert_false(is_due_today(tomorrow))
	end)
end)

describe("is_show_date_reached", function()
	local is_show_date_reached = M._test.is_show_date_reached

	test("nil returns true (show immediately)", function()
		assert_true(is_show_date_reached(nil))
	end)

	test("empty returns true (show immediately)", function()
		assert_true(is_show_date_reached(""))
	end)

	test("past date is reached", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_true(is_show_date_reached(yesterday))
	end)

	test("far future date is not reached", function()
		assert_false(is_show_date_reached("12-31-2099"))
	end)

	test("invalid date returns true (show immediately)", function()
		assert_true(is_show_date_reached("not-a-date"))
	end)
end)

-- ========================================
-- Tests: resolve_date_shortcut
-- ========================================
describe("resolve_date_shortcut", function()
	test("today returns current date", function()
		local result = M.resolve_date_shortcut("today")
		assert_eq(result, os.date("%m-%d-%Y"))
	end)

	test("tomorrow returns next day", function()
		local result = M.resolve_date_shortcut("tomorrow")
		local expected = os.date("%m-%d-%Y", os.time() + 86400)
		assert_eq(result, expected)
	end)

	test("next week returns +7 days", function()
		local result = M.resolve_date_shortcut("next week")
		local expected = os.date("%m-%d-%Y", os.time() + 7 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 5 days", function()
		local result = M.resolve_date_shortcut("5 days")
		local expected = os.date("%m-%d-%Y", os.time() + 5 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 2 weeks", function()
		local result = M.resolve_date_shortcut("2 weeks")
		local expected = os.date("%m-%d-%Y", os.time() + 14 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 3 months", function()
		local result = M.resolve_date_shortcut("3 months")
		local expected = os.date("%m-%d-%Y", os.time() + 90 * 86400)
		assert_eq(result, expected)
	end)

	test("word: two weeks", function()
		local result = M.resolve_date_shortcut("two weeks")
		local expected = os.date("%m-%d-%Y", os.time() + 14 * 86400)
		assert_eq(result, expected)
	end)

	test("case insensitive", function()
		local result = M.resolve_date_shortcut("TODAY")
		assert_eq(result, os.date("%m-%d-%Y"))
	end)

	test("nil returns nil", function()
		assert_nil(M.resolve_date_shortcut(nil))
	end)

	test("empty returns nil", function()
		assert_nil(M.resolve_date_shortcut(""))
	end)

	test("unrecognized returns nil", function()
		assert_nil(M.resolve_date_shortcut("whenever"))
	end)
end)

-- ========================================
-- Tests: generate_todo_id
-- ========================================
describe("generate_todo_id", function()
	local generate_todo_id = M._test.generate_todo_id

	test("stable: same input produces same output", function()
		local todo = { description = "Test task", category = "Personal", added_date = "03-10-2026" }
		local id1 = generate_todo_id(todo)
		local id2 = generate_todo_id(todo)
		assert_eq(id1, id2)
	end)

	test("starts with todo_ prefix", function()
		local todo = { description = "Test", category = "Personal", added_date = "03-10-2026" }
		local id = generate_todo_id(todo)
		assert_true(id:match("^todo_%d+") ~= nil, "should start with todo_")
	end)

	test("different inputs produce different IDs", function()
		local todo1 = { description = "Task A", category = "Personal", added_date = "03-10-2026" }
		local todo2 = { description = "Task B", category = "Personal", added_date = "03-10-2026" }
		local id1 = generate_todo_id(todo1)
		local id2 = generate_todo_id(todo2)
		assert_true(id1 ~= id2, "IDs should differ for different descriptions")
	end)

	test("empty added_date uses fallback", function()
		local todo = { description = "Test", category = "Personal", added_date = "" }
		local id = generate_todo_id(todo)
		assert_not_nil(id)
		assert_true(id:match("^todo_%d+") ~= nil)
	end)
end)

-- ========================================
-- Summary
-- ========================================
summary()
