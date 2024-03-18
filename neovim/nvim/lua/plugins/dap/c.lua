--c.lua
local ok, dap = pcall(require, "dap")
if not ok then
	return
end

--enable logging for trouble shooting
require("dap").set_log_level("TRACE")
dap.adapters.lldb = {
    name = "lldb",
    type = "executable",
    command = '/usr/bin/lldb-vscode-14'
}

dap.configurations.c = {
	{
		name = "Launch",
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
