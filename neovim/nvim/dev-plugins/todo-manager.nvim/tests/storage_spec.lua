-- tests/storage_spec.lua
-- Tests for generate_todo_id
-- Run: cd dev-plugins/todo-manager.nvim && nvim --headless -l tests/storage_spec.lua

local h = dofile("tests/helpers.lua")
local M = h.load_module()
local describe, test = h.describe, h.test
local assert_eq, assert_true = h.assert_eq, h.assert_true
local assert_not_nil = h.assert_not_nil

local generate_todo_id = require("todo-manager.zk")._test.generate_todo_id

-- ========================================
-- Tests: generate_todo_id
-- ========================================
describe("generate_todo_id", function()
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

	test("different categories produce different IDs", function()
		local todo1 = { description = "Same task", category = "Personal", added_date = "03-10-2026" }
		local todo2 = { description = "Same task", category = "Medicine", added_date = "03-10-2026" }
		local id1 = generate_todo_id(todo1)
		local id2 = generate_todo_id(todo2)
		assert_true(id1 ~= id2, "IDs should differ for different categories")
	end)

	test("different dates produce different IDs", function()
		local todo1 = { description = "Same task", category = "Personal", added_date = "03-10-2026" }
		local todo2 = { description = "Same task", category = "Personal", added_date = "03-11-2026" }
		local id1 = generate_todo_id(todo1)
		local id2 = generate_todo_id(todo2)
		assert_true(id1 ~= id2, "IDs should differ for different dates")
	end)
end)

h.summary()
