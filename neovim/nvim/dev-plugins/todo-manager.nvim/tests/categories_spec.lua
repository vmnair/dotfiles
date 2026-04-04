-- tests/categories_spec.lua
-- Tests for validate_category and category management
-- Run: cd dev-plugins/todo-manager.nvim && nvim --headless -l tests/categories_spec.lua

local h = dofile("tests/helpers.lua")
local M = h.load_module()
local categories = require("todo-manager.categories")
local describe, test = h.describe, h.test
local assert_eq, assert_true, assert_false = h.assert_eq, h.assert_true, h.assert_false

-- ========================================
-- Tests: validate_category
-- ========================================
describe("validate_category", function()
	test("exact match case-insensitive", function()
		local ok, result = categories.validate_category("medicine")
		assert_true(ok)
		assert_eq(result, "Medicine")
	end)

	test("exact match uppercase", function()
		local ok, result = categories.validate_category("OMS")
		assert_true(ok)
		assert_eq(result, "OMS")
	end)

	test("empty rejection", function()
		local ok, msg = categories.validate_category("")
		assert_false(ok)
		assert_true(msg:find("empty") ~= nil)
	end)

	test("nil rejection", function()
		local ok, msg = categories.validate_category(nil)
		assert_false(ok)
		assert_true(msg:find("empty") ~= nil)
	end)

	test("fuzzy suggestion for partial match", function()
		local ok, msg = categories.validate_category("med")
		assert_false(ok)
		assert_true(msg:find("Did you mean") ~= nil)
		assert_true(msg:find("Medicine") ~= nil)
	end)

	test("available list for no match", function()
		local ok, msg = categories.validate_category("zzz")
		assert_false(ok)
		assert_true(msg:find("Available") ~= nil)
	end)
end)

-- ========================================
-- Tests: update_static_categories
-- ========================================
describe("update_static_categories", function()
	-- Save original categories to restore after tests
	local original_categories

	test("add new category succeeds", function()
		original_categories = { unpack(M.config.categories) }
		local ok, msg = categories.update_static_categories("TestCategory")
		assert_true(ok)
		assert_true(msg:find("added") ~= nil)
	end)

	test("duplicate category rejected", function()
		local ok, msg = categories.update_static_categories("TestCategory")
		assert_false(ok)
		assert_true(msg:find("already exists") ~= nil)
	end)

	test("cleanup: restore original categories", function()
		-- Restore original categories
		M.config.categories = original_categories
		assert_true(true)
	end)
end)

-- ========================================
-- Tests: filter state
-- ========================================
describe("filter state", function()
	test("initial filter is nil", function()
		categories.current_filter = nil -- reset
		assert_eq(categories.get_current_filter(), nil)
	end)

	test("set and get filter", function()
		-- Stub apply_category_filter_to_current_view since it uses vim APIs
		local original_apply = M.apply_category_filter_to_current_view
		M.apply_category_filter_to_current_view = function() end

		categories.set_category_filter("Medicine")
		assert_eq(categories.get_current_filter(), "Medicine")

		categories.clear_category_filter()
		assert_eq(categories.get_current_filter(), nil)

		M.apply_category_filter_to_current_view = original_apply
	end)

	test("Clear string clears filter", function()
		local original_apply = M.apply_category_filter_to_current_view
		M.apply_category_filter_to_current_view = function() end

		categories.set_category_filter("OMS")
		assert_eq(categories.get_current_filter(), "OMS")

		categories.set_category_filter("Clear")
		assert_eq(categories.get_current_filter(), nil)

		M.apply_category_filter_to_current_view = original_apply
	end)
end)

h.summary()
