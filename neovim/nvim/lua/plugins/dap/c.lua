--c.lua
local ok, dap = pcall(require, "dap")
if not ok then
    print("Error with setting up dap")
	return
end


--enable logging for trouble shooting
require("dap").set_log_level("TRACE")
dap.adapters.lldb = {
	name = "lldb",
	type = "executable",
    command = "/opt/homebrew/opt/llvm/bin/lldb-vscode"

	--command = function()
	--	local handle = io.popen("uname -s")
	--	local result = handle:read("*a")

	--	if result == "Linux" then
	--		return "/usr/bin/lldb"
	--	elseif result == "Darwin" then
	--		return "/opt/homebrew/opt/llvm/bin/lldb-vscode"
	--	else
	--		return "Unsupported operating system"
	--	end
	--end,
}

dap.configurations.c = {

	{
		name = "LLDB: Debug with arguments",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = function()
			local argument_string = vim.fn.input("Program arguments: ")
			if argument_string == "" then
				return {} -- user pressed return, no arguments
			else
				return vim.fn.split(argument_string, " ", true)
			end
		end,
	},
	{
		name = "LLDB: Debug without arguments",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
	},
}
-- Use same confuratons for C and C++
dap.configurations.cpp = dap.configurations.c
