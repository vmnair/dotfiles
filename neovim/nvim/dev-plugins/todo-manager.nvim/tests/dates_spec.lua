-- tests/dates_spec.lua
-- Tests for date functions: is_past_due, is_due_today, is_show_date_reached, resolve_date_shortcut
-- Run: cd dev-plugins/todo-manager.nvim && nvim --headless -l tests/dates_spec.lua

local h = dofile("tests/helpers.lua")
local M = h.load_module()
local dates = require("todo-manager.dates")
local describe, test = h.describe, h.test
local assert_eq, assert_true, assert_false = h.assert_eq, h.assert_true, h.assert_false
local assert_nil, assert_not_nil = h.assert_nil, h.assert_not_nil

-- ========================================
-- Tests: is_past_due
-- ========================================
describe("is_past_due", function()
	test("nil returns false", function()
		assert_false(dates.is_past_due(nil))
	end)

	test("empty string returns false", function()
		assert_false(dates.is_past_due(""))
	end)

	test("yesterday is past due", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_true(dates.is_past_due(yesterday))
	end)

	test("today is not past due", function()
		local today = os.date("%m-%d-%Y")
		assert_false(dates.is_past_due(today))
	end)

	test("tomorrow is not past due", function()
		local tomorrow = os.date("%m-%d-%Y", os.time() + 86400)
		assert_false(dates.is_past_due(tomorrow))
	end)

	test("invalid date string returns false", function()
		assert_false(dates.is_past_due("not-a-date"))
	end)
end)

-- ========================================
-- Tests: is_due_today
-- ========================================
describe("is_due_today", function()
	test("nil returns false", function()
		assert_false(dates.is_due_today(nil))
	end)

	test("empty returns false", function()
		assert_false(dates.is_due_today(""))
	end)

	test("today returns true", function()
		local today = os.date("%m-%d-%Y")
		assert_true(dates.is_due_today(today))
	end)

	test("yesterday returns false", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_false(dates.is_due_today(yesterday))
	end)

	test("tomorrow returns false", function()
		local tomorrow = os.date("%m-%d-%Y", os.time() + 86400)
		assert_false(dates.is_due_today(tomorrow))
	end)
end)

-- ========================================
-- Tests: is_show_date_reached
-- ========================================
describe("is_show_date_reached", function()
	test("nil returns true (show immediately)", function()
		assert_true(dates.is_show_date_reached(nil))
	end)

	test("empty returns true (show immediately)", function()
		assert_true(dates.is_show_date_reached(""))
	end)

	test("past date is reached", function()
		local yesterday = os.date("%m-%d-%Y", os.time() - 86400)
		assert_true(dates.is_show_date_reached(yesterday))
	end)

	test("far future date is not reached", function()
		assert_false(dates.is_show_date_reached("12-31-2099"))
	end)

	test("invalid date returns true (show immediately)", function()
		assert_true(dates.is_show_date_reached("not-a-date"))
	end)
end)

-- ========================================
-- Tests: resolve_date_shortcut
-- ========================================
describe("resolve_date_shortcut", function()
	test("today returns current date", function()
		local result = dates.resolve_date_shortcut("today")
		assert_eq(result, os.date("%m-%d-%Y"))
	end)

	test("tomorrow returns next day", function()
		local result = dates.resolve_date_shortcut("tomorrow")
		local expected = os.date("%m-%d-%Y", os.time() + 86400)
		assert_eq(result, expected)
	end)

	test("next week returns +7 days", function()
		local result = dates.resolve_date_shortcut("next week")
		local expected = os.date("%m-%d-%Y", os.time() + 7 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 5 days", function()
		local result = dates.resolve_date_shortcut("5 days")
		local expected = os.date("%m-%d-%Y", os.time() + 5 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 2 weeks", function()
		local result = dates.resolve_date_shortcut("2 weeks")
		local expected = os.date("%m-%d-%Y", os.time() + 14 * 86400)
		assert_eq(result, expected)
	end)

	test("numeric: 3 months", function()
		local result = dates.resolve_date_shortcut("3 months")
		local expected = os.date("%m-%d-%Y", os.time() + 90 * 86400)
		assert_eq(result, expected)
	end)

	test("word: two weeks", function()
		local result = dates.resolve_date_shortcut("two weeks")
		local expected = os.date("%m-%d-%Y", os.time() + 14 * 86400)
		assert_eq(result, expected)
	end)

	test("case insensitive", function()
		local result = dates.resolve_date_shortcut("TODAY")
		assert_eq(result, os.date("%m-%d-%Y"))
	end)

	test("nil returns nil", function()
		assert_nil(dates.resolve_date_shortcut(nil))
	end)

	test("empty returns nil", function()
		assert_nil(dates.resolve_date_shortcut(""))
	end)

	test("unrecognized returns nil", function()
		assert_nil(dates.resolve_date_shortcut("whenever"))
	end)

	test("get_current_date returns mm-dd-yyyy format", function()
		local result = dates.get_current_date()
		assert_not_nil(result)
		assert_true(result:match("^%d%d%-%d%d%-%d%d%d%d$") ~= nil, "should match mm-dd-yyyy")
	end)
end)

h.summary()
