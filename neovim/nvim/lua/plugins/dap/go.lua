-- go.lua
-- Configuration file for golang

local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
    print("nvim-dap not installed!")
    return
end

require("dap").set_log_level("DEBUG")

-- Get path to dlv executable.
local dlv_path = vim.fn.exepath("dlv")

if dlv_path ~= "" then -- Configure go dap if dlv is installed
    dap.adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
            command = dlv_path,
            args = { "dap", "-l", "127.0.0.1:${port}" },
        },
    }

    dap.configurations = {
        go = {
            {
                type = "go", -- Which adapter to use
                name = "Debug", -- Human readable name
                request = "launch", -- Whether to launch or attach to program
                program = "${file}", -- The buffer we are foccused on when running nvim-dap
            },
        },
    }
else
    warn("Delve executable not installed. Use Mason to install it and try again.")
end