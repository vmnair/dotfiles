-- todo-manager/categories.lua
-- Category validation, management, and filter state

local M = {}

-- Filter state
M.current_filter = nil -- nil means "Clear" (show all), otherwise category name

-- Get current filter state
function M.get_current_filter()
	return M.current_filter
end

-- Set category filter (in-place filtering)
function M.set_category_filter(category)
	if category == "Clear" or category == "clear" or category == "" then
		M.current_filter = nil
	else
		M.current_filter = category
	end
	-- Apply filter to current view if it's a todo buffer
	require("todo-manager").apply_category_filter_to_current_view()
end

-- Clear category filter (show all todos)
function M.clear_category_filter()
	M.current_filter = nil
	require("todo-manager").apply_category_filter_to_current_view()
end

-- Validate category name and provide suggestions
function M.validate_category(name)
	local config = require("todo-manager").config

	if not name or name == "" then
		return false, "Category name cannot be empty"
	end

	name = name:lower()
	local valid_categories = {}
	for _, cat in ipairs(config.categories) do
		table.insert(valid_categories, cat:lower())
	end

	-- Exact match (case insensitive)
	for i, cat in ipairs(valid_categories) do
		if cat == name then
			return true, config.categories[i] -- return proper case
		end
	end

	-- Fuzzy matching for suggestions
	local suggestions = {}
	for i, cat in ipairs(valid_categories) do
		if cat:find(name, 1, true) or name:find(cat, 1, true) then
			table.insert(suggestions, config.categories[i])
		end
	end

	local available = table.concat(config.categories, ", ")
	if #suggestions > 0 then
		local suggestion_str = table.concat(suggestions, ", ")
		return false, "Category '" .. name .. "' not found. Did you mean: " .. suggestion_str .. "?"
	else
		return false, "Category '" .. name .. "' not found. Available: " .. available
	end
end

-- Get todo counts for each category (for menu display)
function M.get_category_todo_counts()
	local tm = require("todo-manager")
	local active_todos = tm.get_active_todos()
	local counts = {}

	-- Initialize counts for all categories
	for _, category in ipairs(tm.config.categories) do
		counts[category] = 0
	end

	-- Count todos by category
	local total_count = 0
	for _, todo in ipairs(active_todos) do
		local cat = todo.category or "Personal" -- default fallback
		if counts[cat] ~= nil then
			counts[cat] = counts[cat] + 1
		end
		total_count = total_count + 1
	end

	counts["Clear"] = total_count -- "Clear" shows all todos
	return counts
end

-- Update static categories list (for new category additions)
function M.update_static_categories(new_category)
	local config = require("todo-manager").config

	-- Check if category already exists
	for _, cat in ipairs(config.categories) do
		if cat == new_category then
			return false, "Category '" .. new_category .. "' already exists"
		end
	end

	-- Add new category to config
	table.insert(config.categories, new_category)
	return true, "Category '" .. new_category .. "' added successfully"
end

-- Remove category with safety checks
function M.remove_category_with_checks(category)
	local tm = require("todo-manager")
	local config = tm.config

	-- Check if category exists
	local found = false
	for _, cat in ipairs(config.categories) do
		if cat == category then
			found = true
			break
		end
	end

	if not found then
		return false, "Category '" .. category .. "' not found"
	end

	-- Check for active todos in this category
	local active_todos = tm.get_active_todos()
	local active_count = 0
	for _, todo in ipairs(active_todos) do
		if todo.category == category then
			active_count = active_count + 1
		end
	end

	-- Check for scheduled todos in this category
	local scheduled_todos = tm.get_scheduled_todos()
	local scheduled_count = 0
	for _, todo in ipairs(scheduled_todos) do
		if todo.category == category then
			scheduled_count = scheduled_count + 1
		end
	end

	-- Prevent removal if active or scheduled todos exist
	if active_count > 0 or scheduled_count > 0 then
		local message = "Cannot remove category '" .. category .. "'. "
		if active_count > 0 then
			message = message .. "Complete " .. active_count .. " active todos"
		end
		if scheduled_count > 0 then
			if active_count > 0 then
				message = message .. " and "
			end
			message = message .. "Complete " .. scheduled_count .. " scheduled todos"
		end
		message = message .. " first."
		return false, message
	end

	-- Safe to remove category
	for i, cat in ipairs(config.categories) do
		if cat == category then
			table.remove(config.categories, i)
			break
		end
	end

	-- Handle active filter state
	if M.current_filter == category then
		M.current_filter = nil -- Auto-clear filter
		tm.apply_category_filter_to_current_view()
		return true, "Category '" .. category .. "' removed. Filter cleared, showing all todos."
	end

	return true, "Category '" .. category .. "' removed successfully"
end

-- Add a new category with icon
function M.add_new_category(name, icon)
	-- Use the new static category system
	local success, message = M.update_static_categories(name)
	if not success then
		print("✗ " .. message)
		return false
	end

	-- Add icon to config
	local config = require("todo-manager").config
	config.category_icons[name] = icon
	print("✓ Category '" .. name .. "' (" .. icon .. ") added successfully")
	print("  Available in TodoFilter, TodoBuilder, and all filtering options")
	return true
end

return M
