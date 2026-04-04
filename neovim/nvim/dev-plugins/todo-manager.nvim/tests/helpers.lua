-- tests/helpers.lua
-- Shared test framework and vim stubs for todo-manager tests
-- Usage: local h = dofile("tests/helpers.lua")

local H = {}

-- ========================================
-- Mini Test Framework
-- ========================================
local passed, failed, errors = 0, 0, {}
local current_group = ""

function H.describe(name, fn)
	current_group = name
	print("\n" .. name)
	fn()
end

function H.test(name, fn)
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

function H.assert_eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "") .. " expected: " .. tostring(expected) .. ", got: " .. tostring(actual))
	end
end

function H.assert_true(val, msg)
	if not val then error((msg or "") .. " expected true, got: " .. tostring(val)) end
end

function H.assert_false(val, msg)
	if val then error((msg or "") .. " expected false, got: " .. tostring(val)) end
end

function H.assert_nil(val, msg)
	if val ~= nil then error((msg or "") .. " expected nil, got: " .. tostring(val)) end
end

function H.assert_not_nil(val, msg)
	if val == nil then error((msg or "") .. " expected non-nil") end
end

function H.assert_table_len(tbl, len, msg)
	H.assert_eq(#tbl, len, (msg or "") .. " table length")
end

function H.summary()
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
-- Vim Stubs
-- ========================================
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
	tbl_extend = function(_, t1, t2)
		local result = {}
		for k, v in pairs(t1 or {}) do result[k] = v end
		for k, v in pairs(t2 or {}) do result[k] = v end
		return result
	end,
	ui = { select = function() end, input = function() end },
	loop = { fs_stat = function() return nil end },
	trim = function(s) return s:match("^%s*(.-)%s*$") end,
	split = function(s, sep, opts)
		local result = {}
		for part in s:gmatch("[^" .. sep .. "]+") do
			if not (opts and opts.trimempty) or part ~= "" then
				table.insert(result, part)
			end
		end
		return result
	end,
	pesc = function(s) return s:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1") end,
}

-- ========================================
-- Module Loading
-- ========================================
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

function H.load_module()
	local ok, M = pcall(require, "todo-manager")
	if not ok then
		print("ERROR: Failed to load todo-manager: " .. tostring(M))
		os.exit(1)
	end
	return M
end

return H
