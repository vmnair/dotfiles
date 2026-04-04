-- todo-manager/parser.lua
-- Pure parsing and formatting logic for todo lines

local M = {}

-- Parse a todo line into components
function M.parse_todo_line(line)
	if not line or line == "" or not line:match("^%s*%-") then
		return nil
	end

	local config = require("todo-manager").config

	local todo = {
		completed = false,
		description = "",
		category = "Personal",
		tags = {},
		due_date = "",
		show_date = "",
		added_date = "",
		completion_date = "",
		has_note = false,
		raw_line = line,
	}

	-- Check if completed
	if line:match("%[x%]") or line:match("%[X%]") then
		todo.completed = true
	end

	-- Parse clean format: - [ ] icon Description [Show: date] [Due: date] #tag (added_date)
	local desc_part = line:match("^%s*%- %[.%] (.+)$")
	if desc_part then
		-- Extract show date
		local show_match = desc_part:match("%[Show: ([%d%-]+)%]")
		if show_match then
			todo.show_date = show_match
			desc_part = desc_part:gsub("%s*%[Show: [%d%-]+%]", "")
		end

		-- Extract due date
		local due_match = desc_part:match("%[Due: ([%d%-]+)%]")
		if due_match then
			todo.due_date = due_match
			desc_part = desc_part:gsub("%s*%[Due: [%d%-]+%]", "")
		end

		-- Detect and remove note link indicator (before added_date extraction,
		-- since 󰈙 appears after the date in storage format and would prevent the regex match)
		if desc_part:find("󰈙", 1, true) then
			todo.has_note = true
			desc_part = desc_part:gsub("󰈙", ""):gsub("^%s+", ""):gsub("%s+$", "")
		end

		-- Extract added date (in parentheses at end)
		local added_match = desc_part:match("%(([%d%-]+)%)%s*$")
		if added_match then
			todo.added_date = added_match
			desc_part = desc_part:gsub("%s*%(([%d%-]+)%)%s*$", "")
		end

		-- Extract tags
		for tag in desc_part:gmatch("#(%w+)") do
			table.insert(todo.tags, tag)
		end
		desc_part = desc_part:gsub("%s*#%w+", "")

		-- Extract category from icon and remove ALL icons from description
		for category, icon in pairs(config.category_icons) do
			if desc_part:find(icon, 1, true) then
				todo.category = category
				desc_part = desc_part:gsub(icon, ""):gsub("^%s+", ""):gsub("%s+$", "")
				break
			end
		end

		-- Also remove any fallback notepad icons that might have been added previously
		desc_part = desc_part:gsub("📝", ""):gsub("^%s+", ""):gsub("%s+$", "")

		todo.description = desc_part:gsub("^%s+", ""):gsub("%s+$", "")
	end

	return todo
end

-- Format todo line for file output
function M.format_todo_line(todo, context)
	local config = require("todo-manager").config

	local checkbox = todo.completed and "- [x]" or "- [ ]"
	local icon = config.category_icons[todo.category] or "📝"
	local description = todo.description

	-- Build the formatted line
	local line = checkbox .. " " .. icon .. " " .. description

	-- Add show date (for scheduled and storage contexts)
	if (context == "scheduled" or context == "storage") and todo.show_date and todo.show_date ~= "" then
		line = line .. " [Show: " .. todo.show_date .. "]"
	end

	-- Add due date
	if todo.due_date and todo.due_date ~= "" then
		line = line .. " [Due: " .. todo.due_date .. "]"
	end

	-- Add tags
	if todo.tags and type(todo.tags) == "table" and #todo.tags > 0 then
		line = line .. " #" .. table.concat(todo.tags, " #")
	elseif todo.tags and type(todo.tags) == "string" and todo.tags ~= "" then
		line = line .. " " .. todo.tags
	end

	-- Add added date (in parentheses) - only for non-active contexts
	if context ~= "active" and todo.added_date and todo.added_date ~= "" then
		line = line .. " (" .. todo.added_date .. ")"
	end

	-- Add note link indicator
	if todo.has_note then
		line = line .. " 󰈙"
	end

	return line
end

return M
