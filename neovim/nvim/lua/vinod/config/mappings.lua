-- mappings.lua

--[[
-- This function adds ability ti add desc to local options which has
-- noremap and silent.
--]]
local map = function(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

--This function adds ability to add keymaps to different modes
local map_for_modes = function(modes, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	for _, mode in ipairs(modes) do
		local rhs_command = rhs
		if mode == "t" then
			rhs_command = [[<C-\><C-n>]] .. rhs
		end
		vim.api.nvim_set_keymap(mode, lhs, rhs_command, opts)
	end
end

-- expand ~ to $HOME
vim.keymap.set("n", "gf", function()
	local file = vim.fn.expand("<cfile>")
	file = file:gsub("^~", vim.env.HOME)
	vim.cmd("edit " .. file)
end)

map("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
map("n", "<Esc>", ":nohl<CR><Esc>", { desc = "Clear search highlights" })
-- Normal mode center next selection
map("n", "n", "nzz", { desc = "Move to next search result and center line." })
map("n", "N", "Nzz", { desc = "Move to Previous search result and center line." })

map("n", "x", '"_x', { desc = "Delete the char under cursor to void in normal mode" })
map("v", "x", '"_x', { desc = "Delete the char cursor to void in visual mode" })
-- Format pasted line
map("n", "p", "p==", { desc = "Auto formats / indents the pasted text" })
-- Save file (changed from <C-s> to avoid conflict with tmux sessionizer)
map("n", "<leader>w", "<Cmd>w<CR>", { desc = "Saves current buffer" })
-- Close Neovim
map("n", "<C-q>", "<Cmd>q<CR>", { desc = "Exit Neovim" })
-- Vertical split
map("n", "<leader>+", "<Cmd>vsplit<CR>", { desc = "Splits vertically" })
-- Horizontal split
map("n", "<leader>-", "<Cmd>split<CR>", { desc = "Splits horizondally" })
-- Resize splits
map("n", "<S-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Resize pane vertically" })
map("n", "<S-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Resize pane vertically" })
map("n", "<S-Up>", "<Cmd>resize -2<CR>", { desc = "Resize pane up" })
map("n", "<S-Down>", "<Cmd>resize +2<CR>", { desc = "Resize pane down" })
-- Indent/Unindent selected text with Tab and Shift+Tab
map("v", ">", ">gv", { desc = "Indent selected line to right" })
map("v", "<", "<gv", { desc = "Indent selected line to left" })
-- Buffer management
map("n", "<leader>bn", ":enew<CR>", { desc = "Create new buffer" })
map("n", "]b", ":bnext<CR>", { desc = "Move to next buffer" })
map("n", "[b", ":bprevious<CR>", { desc = "Move to previous buffer" })
map("n", "]B", ":blast<CR>", { desc = "Move to last buffer" })
map("n", "[B", ":bfirst<CR>", { desc = "Move to first buffer" })

-- Quickfix navigation keymaps
map("n", "]q", ":cnext<CR>", { desc = "Move to next quickfix item" })
map("n", "[q", ":cprevious<CR>", { desc = "Move to previous quickfix item" })
map("n", "]Q", ":clast<CR>", { desc = "Move to last quickfix item" })
map("n", "[Q", ":cfirst<CR>", { desc = "Move to first quickfix item" })
map("n", "<leader>qo", ":copen<CR>", { desc = "Open quickfix window" })
map("n", "<leader>qc", ":cclose<CR>", { desc = "Close quickfix window" })

-- Markdown formatting keymaps
map("v", "<leader>mb", 'c**<C-r>"**<Esc>', { desc = "Markdown bold" })
map("v", "<leader>mi", 'c*<C-r>"*<Esc>', { desc = "Markdown italic" })
map("v", "<leader>mc", 'c`<C-r>"`<Esc>', { desc = "Markdown code" })

-- Windows movement
map_for_modes({ "n", "t", "v" }, "<C-h>", "<C-w>h", { desc = "Move to Left Window" })
map_for_modes({ "n", "t", "v" }, "<C-j>", "<C-w>j", { desc = "Move to Down Window" })
map_for_modes({ "n", "t", "v" }, "<C-k>", "<C-w>k", { desc = "Move to Top Window" })
map_for_modes({ "n", "t", "v" }, "<C-l>", "<C-w>l", { desc = "Move to Right Window" })

-- Lazy keymaps
map("n", "<leader>lo", "<Cmd>Lazy<CR>", { desc = "Lazy - Open" })
map("n", "<leader>lu", "<Cmd>Lazy update<CR>", { desc = "Lazy - Update" })

-- LaTeX keymaps
map("n", "<leader>lv", "<Cmd>LatexCompileAndOpenPDF<CR>", { desc = "Compile & View LaTeX file." })
