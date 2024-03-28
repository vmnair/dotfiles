--c.lua
local ok, dap = pcall(require, "dap")
if not ok then
	print("Error with setting up dap")
	return
end

-- Function to check operating system
function GetOS()
	if os.getenv("OS") ~= nil and os.getenv("OS"):match("Windows") then
		return "Windows"
	elseif os.getenv("HOME") ~= nil then
		if os.getenv("XDG_CURRENT_DESKTOP") ~= nil then
			return "Linux"
		else
			return "macOS"
		end
	else
		return "Unknown"
	end
end

local os = GetOS()
local path_to_vscode
if os == "macOS" then
	path_to_vscode = "/opt/homebrew/opt/llvm/bin/lldb-vscode"
elseif os == "Linux" then
    path_to_vscode = "/usr/bin/lldb"
end

dap.adapters.lldb = {
	name = "lldb",
	type = "executable",
	command = path_to_vscode,

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
