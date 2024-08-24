-- -- autocmds.lua
-- Move the help file to the right insted of the bottom

vim.api.nvim_create_autocmd("BufWinEnter", {
	pattern = "*.txt",
	callback = function()
		if vim.bo.filetype == "help" then
			vim.cmd("wincmd L") -- L for moving to the right
		end
	end,
})
-- LaTeX configuration
-- -- Create an autocmd group in Lua
vim.api.nvim_create_augroup("VimtexConfig", { clear = true })

-- Open Latex file in Skim
vim.api.nvim_create_user_command("LatexOpenPDF", function()
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

--
-- -- Define the autocmds for LaTeX files
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = "tex",
-- 	group = "VimtexConfig",
-- 	callback = function()
-- 		vim.o.foldmethod = "expr"
-- 		vim.o.foldexpr = "vimtex#fold#level(v:lnum)"
-- 		vim.o.foldtext = "vimtex#fold#text()"
-- 		vim.o.foldlevel = 2
-- 	end,
-- })

-- Keymappings
vim.api.nvim_set_keymap("n", "<leader>lv", ":LatexOpenPDF<CR>", { noremap = true, silent = true })
