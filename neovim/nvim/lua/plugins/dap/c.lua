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
         error("Unknown operating system", 1)
 		return "Unknown"
 	end
 end


 local system = GetOS()
 print("OS = " .. system)

 local path_to_lldb
 if system == "macOS" then
 	path_to_lldb = "/opt/homebrew/opt/llvm/bin/lldb-vscode"
 elseif system  == "Linux" then
     path_to_lldb = "lldb-vscode-14" --lldb-vscode-14
 else
     error("Unknown operating system: " .. system)
 end

dap.adapters.lldb = {
	name = "lldb",
	type = "executable",
	command = path_to_lldb

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
