-- dap.init.lua

local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
        "jay-babu/mason-nvim-dap.nvim",
        "rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
		"leoluz/nvim-dap-go",
		"nvim-telescope/telescope-dap.nvim",
		-- "wojciech-kulik/xcodebuild.nvim",
		--"mortepau/codicons.nvim",
	},

	-- ft = { 'c', 'go', 'lua', 'python' },
	ft = { "c", "lua", "go" },
	version = "*",
}

M.config = function()
	local keymap = vim.keymap.set
    local sign = vim.fn.sign_define

    local dap = require("dap")
	dap.set_log_level("DEBUG")

   local dapui = require("dapui")

    --TODO: research 
	--local telescope_dap = require("telescope").load_extension("dap")

    --TODO: Check about installing C debuggers here
	require("mason-nvim-dap").setup({
		ensure_installed = { "delve" },
	})
	require("dapui").setup()
	require("nvim-dap-virtual-text").setup({
		virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
	})


	sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
	sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
	sign("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })

	-- Keymaps
	keymap("n", "<F5>", function()
		dap.continue()
	end) -- Start debug
	keymap("n", "<F6>", function()
		dap.step_over()
	end)
	keymap("n", "<F7>", function()
		dap.step_into()
	end)
	keymap("n", "<F8>", function()
		dap.step_out()
	end)
	keymap("n", "<F12>", function()
		dap.disconnect({ terminateDebuggee = true })
	end)

	keymap("n", "<Leader>db", function()
		dap.toggle_breakpoint()
	end, { desc = "Toggle breakpoint" })
	keymap("n", "<Leader>dB", function()
		dap.set_breakpoint()
	end, { desc = "Set breakpoint" })
	keymap("n", "<Leader>dk", function()
		dap.clear_breakpoints()
	end, { desc = "Clear breakpoints" })
	-- Log Logpoint
	keymap("n", "<Leader>dl", function()
		dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
	end, { desc = "Set log-point" })
	keymap("n", "<Leader>dr", function()
		dap.repl.open()
	end, { desc = "Open dap REPL" }) -- Open dap repl
	-- keymap('n', '<Leader>dl', function() dap.run_last() end)
	keymap({ "n", "v" }, "<Leader>dh", function() -- Evaluate symbol on hover
		require("dap.ui.widgets").hover()
	end, { desc = "Hover value" })
	keymap({ "n", "v" }, "<Leader>dp", function() -- Preview
		require("dap.ui.widgets").preview()
	end, { desc = "Preview value" })
	keymap("n", "<Leader>df", function() -- Show frames in a centered window
		local widgets = require("dap.ui.widgets")
		widgets.centered_float(widgets.frames)
	end, { desc = "Frame data" })
	keymap("n", "<Leader>ds", function()
		local widgets = require("dap.ui.widgets")
		widgets.centered_float(widgets.scopes)
	end, { desc = "Scopes" })

    keymap("n", "<Leader>du", function()
        dap.run_to_cursor()
	end, { desc = "Run to cursor" })
	-- dapui configuration
	keymap("n", "<leader>do", function()
		dapui.open()
	end, { desc = "Open debugger UI" })
	keymap("n", "<leader>dc", function()
		dapui.close()
	end, { desc = "Close debugger UI" })

	-- Need to conditionally load dap.c
   -- if vim.fn.executable("lldb-dap") == 1 or vim.fn.executable("lldb-vscode-14") then
   -- 	require("plugins.dap.c")
   -- end
    --require('plugins.dap.go')
	-- require('plugins.dap.lua')
	-- require('plugins.dap.python')
    require('plugins.dap.c')
    require('plugins.dap.go')
end


return M
