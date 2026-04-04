-- todo-manager/dates.lua
-- Pure date logic for todo manager

local M = {}

-- Get current date in mm-dd-yyyy format
function M.get_current_date()
	return os.date("%m-%d-%Y")
end

-- Check if a show date has arrived (today or in the past)
function M.is_show_date_reached(date_str)
	if not date_str or date_str == "" then
		return true -- No show date means show immediately
	end

	-- Parse the date string (mm-dd-yyyy)
	local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
	if not month or not day or not year then
		return true -- Invalid date means show immediately
	end

	-- Convert to timestamp for comparison
	local year_num, month_num, day_num = tonumber(year), tonumber(month), tonumber(day)
	if not year_num or not month_num or not day_num then
		return true -- Invalid numbers mean show immediately
	end

	local show_time = os.time({
		year = year_num,
		month = month_num,
		day = day_num,
		hour = 0,
		min = 0,
		sec = 0,
	})

	local current_time = os.time()
	return current_time >= show_time
end

-- Check if a date is past due
function M.is_past_due(date_str)
	if not date_str or date_str == "" then
		return false
	end

	local current_date = M.get_current_date()
	local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
	local cur_month, cur_day, cur_year = current_date:match("(%d+)-(%d+)-(%d+)")

	if not month or not cur_month then
		return false
	end

	local date_time = os.time({ year = tonumber(year) --[[@as integer]], month = tonumber(month) --[[@as integer]], day = tonumber(day) --[[@as integer]] })
	local current_time = os.time({ year = tonumber(cur_year) --[[@as integer]], month = tonumber(cur_month) --[[@as integer]], day = tonumber(cur_day) --[[@as integer]] })

	return date_time < current_time
end

-- Check if a date is due today
function M.is_due_today(date_str)
	if not date_str or date_str == "" then
		return false
	end
	return date_str == M.get_current_date()
end

-- Resolve date shortcuts like "tomorrow", "next week", "5 days", etc.
function M.resolve_date_shortcut(keyword)
	if not keyword or keyword == "" then
		return nil
	end

	keyword = keyword:lower():gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace

	-- Special cases
	if keyword == "today" then
		return os.date("%m-%d-%Y")
	elseif keyword == "tomorrow" then
		local tomorrow = os.time() + (24 * 60 * 60) -- Add 1 day in seconds
		return os.date("%m-%d-%Y", tomorrow)
	elseif keyword == "next week" then
		local next_week = os.time() + (7 * 24 * 60 * 60) -- Add 7 days
		return os.date("%m-%d-%Y", next_week)
	elseif keyword == "this weekend" then
		-- Find next Saturday
		local current_time = os.time()
		local current_date = os.date("*t", current_time)
		local days_to_saturday = (6 - current_date.wday + 1) % 7 -- wday: 1=Sunday, 7=Saturday
		if days_to_saturday == 0 then -- Today is Saturday
			days_to_saturday = 7 -- Next Saturday
		end
		local saturday_time = current_time + (days_to_saturday * 24 * 60 * 60)
		return os.date("%m-%d-%Y", saturday_time)
	end

	-- Pattern matching for "[number] [unit]" or "[word] [unit]"
	local number_text, unit = keyword:match("^(%S+)%s+(%S+)$")
	if not number_text or not unit then
		return nil
	end

	-- Convert text numbers to actual numbers
	local text_to_number = {
		one = 1,
		two = 2,
		three = 3,
		four = 4,
		five = 5,
		six = 6,
		seven = 7,
		eight = 8,
		nine = 9,
		ten = 10,
		eleven = 11,
		twelve = 12,
	}

	local number = tonumber(number_text) or text_to_number[number_text:lower()]
	if not number or number < 1 or number > 12 then
		return nil
	end

	-- Calculate days based on unit
	local days = 0
	unit = unit:lower()
	if unit == "day" or unit == "days" then
		days = number
	elseif unit == "week" or unit == "weeks" then
		days = number * 7
	elseif unit == "month" or unit == "months" then
		days = number * 30 -- Approximate
	elseif unit == "year" or unit == "years" then
		days = number * 365 -- Approximate
	else
		return nil
	end

	-- Calculate future date
	local future_time = os.time() + (days * 24 * 60 * 60)
	return os.date("%m-%d-%Y", future_time)
end

return M
