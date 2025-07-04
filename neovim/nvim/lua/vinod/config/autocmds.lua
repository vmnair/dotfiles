-- autocmds.lua

-- Markdown configuration
local MarkdownConfig = vim.api.nvim_create_augroup("MarkdownConfig", { clear = true })

-- Enables line wrapping and sets text width for markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = MarkdownConfig,
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.textwidth = 80
	end,
})

-- Move the help file to the right insted of the bottom
vim.api.nvim_create_autocmd("BufWinEnter", {
	pattern = "*.txt",
	callback = function()
		if vim.bo.filetype == "help" then
			vim.cmd("wincmd L") -- L for moving to the right
		end
	end,
})

-- Filetype specific configuration
-- C configuration

-- Create an augroup for autoindenting C files
local AutoindentC = vim.api.nvim_create_augroup("AutoindentC", { clear = true })

-- Add an autocmd to the augroup to autoindent C files on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.c",
	group = AutoindentC,
	callback = function()
		-- Save the current cursor position
		local pos = vim.api.nvim_win_get_cursor(0)
		-- Reindent the entire file
		vim.cmd("normal! gg=G")
		-- Restore the cursor position
		vim.api.nvim_win_set_cursor(0, pos)
	end,
})

-- LaTeX configuration
vim.api.nvim_create_augroup("VimtexConfig", { clear = true })

-- LatexCompileAndOpenPDF (User Command)
--Compile & Open Latex file in PDF viewer
vim.api.nvim_create_user_command("LatexCompileAndOpenPDF", function()
	local file_extension = vim.fn.expand("%:e")
	if file_extension ~= "tex" then
		print("Module: autocmds.lua\ncmd: LatexCompileAndOpenPDF\nThis command only works for tex files.")
		return
	end

	local pdf_file = vim.fn.expand("%:r") .. ".pdf"
	if vim.fn.filereadable(pdf_file) == 1 then
		vim.cmd("VimtexView")
	else
		vim.cmd("VimtexCompile")
		vim.defer_fn(function()
			vim.cmd("VimtexView")
		end, 2000)
	end
end, {})

-- LatexCompileTex (User Command)
-- Compile latex file.
vim.api.nvim_create_user_command("LatexCompileTex", function()
	local file_extension = vim.fn.expand("%:e")
	if file_extension ~= "tex" then
		print("Module: autocmds.lua\ncmd: LatexCompileTex\nThis command only works for tex files.")
		return
	end
	-- Tex file exists, so just compile it.
	vim.cmd("VimtexCompile")
end, {})

-- Compilation on save feature
local update_timer = nil
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.tex",
	group = "VimtexConfig",
	callback = function()
		-- Check if vimtex plugin is active, if not active  just return
		if not vim.b.vimtex then
			return
		end

		-- Cancel any pending update
		if update_timer then
			vim.fn.timer_stop(update_timer)
		end

		-- Check if vimtex compiler is present and running
		if not (vim.b.vimtex.compiler and vim.b.vimtex.compiler.is_running) then
			vim.cmd("VimtexCompile") -- prevent multiple compilations
		end

		-- Set  timer to refresh the view after compilation
		update_timer = vim.fn.timer_start(2000, function()
			vim.cmd("VimtexView")
			update_timer = nil
		end)
	end,
})

-- Enable [[ to trigger the completion menu in markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		if vim.lsp.omnifunc then
			-- Set the omnifunc to the LSP's omnifunc
			vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
			-- Create a buffer-local mapping for [[ to trigger completion
			vim.api.nvim_buf_set_keymap(0, "i", "[[", "[[<C-x><C-o>", { noremap = true, silent = true })
		else
			vim.notify("LSP omnifunc not available", vim.log.levels.WARN)
		end
		-- assign the omnifunc of  lsp to local buffer (markdown filetype)
		-- vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
	end,
})

-- Keymaps for Copilot
-- Open Copilot Panel
vim.keymap.set("n", "<M-p>", "<cmd>Copilot panel<cr>", { desc = "Open Copilot Panel" })
-- Close the Copilot panel
vim.keymap.set("n", "<M-c>", "<cmd>Copilot panel close<cr>", { desc = "Close Copilot Panel" })
-- Traverse Copilot Suggestions
vim.keymap.set("i", "<M-j>", "<cmd>Copilot next<cr>", { desc = "Next Copilot Suggestion" })
vim.keymap.set("i", "<M-k>", "<cmd>Copilot prev<cr>", { desc = "Previous Copilot Suggestion" })
-- Accept Copilot Suggestion
vim.keymap.set("i", "<M-l>", "<cmd>Copilot accept<cr>", { desc = "Accept Copilot Suggestion" })
-- Dismiss Copilot Suggestion
vim.keymap.set("i", "<M-d>", "<cmd>Copilot dismiss<cr>", { desc = "Dismiss Copilot Suggestion" })
-- Refresh Copilot Suggestions
vim.keymap.set("i", "<M-r>", "<cmd>Copilot refresh<cr>", { desc = "Refresh Copilot Suggestions" })
