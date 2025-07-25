--c.lua
local c_dap_setup = function()
	local ok, dap = pcall(require, "dap")
	if not ok then
		print("Error with setting up dap")
		return
	end

	-- Setup LLDB Executable based on Operating system
	local system = require("vinod.config.util").GetOS()
	local path_to_lldb
	if system == "macOS" then
		-- install lldb using home brew
		-- try which lldb-dap in a terminal
		path_to_lldb = "/opt/homebrew/opt/llvm/bin/lldb-dap"
	elseif system == "Linux" then
		path_to_lldb = "lldb-vscode-14" --lldb-vscode-14
	else
		vim.notify("OS Unknown: Cannot setup debugger!", vim.log.levels.WARN)
	end

	dap.adapters.lldb = {
		name = "lldb",
		type = "executable",
		command = path_to_lldb,
	}

	dap.configurations.c = {
		{
			name = "LLDB: Debug with arguments",
			type = "lldb",
			request = "launch",
			program = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/app", "file")
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
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/app", "file")
			end,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
		},
	}
	-- Use same confuratons for C and C++
	dap.configurations.cpp = dap.configurations.c
	-- print("DAP Setup completed for C/C++")
end

-- Set up autocommand for C & C++ files
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "c", "cpp" },
	callback = c_dap_setup,
})
