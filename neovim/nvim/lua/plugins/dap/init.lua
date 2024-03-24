-- dap.init.lua
local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"theHamsta/nvim-dap-virtual-text",
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		--"mortepau/codicons.nvim",
	},

	-- ft = { 'c', 'go', 'lua', 'python' },
	ft = { "c", "lua" },
	version = "*",
}

M.config = function()
	local dap = require("dap")
	local dapui = require("dapui")
	local keymap = vim.keymap.set

	require("dapui").setup()
	require("nvim-dap-virtual-text").setup({
		virt_text_pos = "eol", -- eol or inline
	})
	--require("neodev").setup()

	keymap("n", "<F5>", function()
		dap.continue()
	end) -- Start debug
	keymap("n", "<F6>", function()
		dap.step_over()
	end) -- Step over
	keymap("n", "<F7>", function()
		dap.step_into()
	end) -- Step into
	keymap("n", "<F8>", function()
		dap.step_out()
	end) -- Step out
	keymap("n", "<F12>", function()
		dap.disconnect({ terminateDebuggee = true })
	end) -- Step out
	keymap("n", "<Leader>db", function()
		dap.toggle_breakpoint()
	end)
	keymap("n", "<Leader>dB", function()
		dap.list_breakpoints()
	end)
	keymap("n", "<Leader>dc", function()
		dap.clear_breakpoints()
	end)
	-- Log Logpoint
	keymap("n", "<Leader>dl", function()
		dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
	end)
	keymap("n", "<Leader>dr", function()
		dap.repl.open()
	end) -- Open dap repl
	-- keymap('n', '<Leader>dl', function() dap.run_last() end)
	keymap({ "n", "v" }, "<Leader>dh", function() -- Evaluate symbol on hover
		require("dap.ui.widgets").hover()
	end)
	keymap({ "n", "v" }, "<Leader>dp", function() -- Preview
		require("dap.ui.widgets").preview()
	end)
	keymap("n", "<Leader>df", function() -- Show frames in a centered window
		local widgets = require("dap.ui.widgets")
		widgets.centered_float(widgets.frames)
	end)
	keymap("n", "<Leader>ds", function()
		local widgets = require("dap.ui.widgets")
		widgets.centered_float(widgets.scopes)
	end)

	-- dapui configuration
	 dap.listeners.before.attach.dapui_config = function()
	 	dapui.open()
	 end
	dap.listeners.before.launch.dapui_config = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated.dapui_config = function()
		dapui.close()
	end
	dap.listeners.before.event_exited.dapui_config = function()
		dapui.close()
	end
	--local telescope_dap = require("telescope").extensions.dap

	--keymap({ "n", "v" }, "<leader>d?", function()
	--    telescope_dap.commands({})
	--end, { silent = true, desc = "DAP builtin commands" })
	-- keymap({ 'n', 'v' }, '<leader>dl', function()
	--     telescope_dap.list_breakpoints({})
	-- end, { silent = true, desc = 'DAP breakpoint list' })
	-- keymap({ 'n', 'v' }, '<leader>df', function()
	--     telescope_dap.frames()
	-- end, { silent = true, desc = 'DAP frames' })
	-- keymap({ 'n', 'v' }, '<leader>dv', function()
	--     telescope_dap.variables()
	-- end, { silent = true, desc = 'DAP variables' })
	-- keymap({ 'n', 'v' }, '<leader>dc', function()
	--     telescope_dap.configurations()
	-- end, { silent = true, desc = 'DAP debugger configurations' })

	-- configure dap-ui and language adapaters
	-- require('plugins.dap.ui')
	-- if vim.fn.executable('dlv') == 1 then
	--     require('plugins.dap.go')
	-- end
	if vim.fn.executable("gdb") == 1 then
		require("plugins.dap.c")
	end
	-- require('plugins.dap.lua')
	-- require('plugins.dap.python')

	-- require('telescope').load_extension('dap')
end

return M
