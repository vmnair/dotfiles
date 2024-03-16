--c.lua
local ok, dap = pcall(require, 'dap')
if not ok then
    return
end

dap.adapters.cppdbg = {
    type = "executable",
    command = "~/.vscode/extensions/ms-vscode.cpptools-1.19.7-linux-64/bin/cpptools",
    args = {},
    -- Enviornments that need to be passed to the adapters
    env = {
        ["LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY"] = "YES",
    }
}


dap.configurations.cpp = {
    {
        name = "Launch",
        type = "cppdbg",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fngetcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder",
        stopOnEntry = true,
        setupCommands = {
            {
                text = "-enable-pretty-printing",
                description = "enable pretty printing",
                ignoreFailures = false
            },
        },
        -- Specify more settings here.

    },
}

-- Use same confuratons for C and C++
dap.configurations.c = dap.configurations.cpp
