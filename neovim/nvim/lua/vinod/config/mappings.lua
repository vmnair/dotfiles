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

map("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
map("n", "<Esc>", ":nohl<CR><Esc>", { desc = "Clear search highlights" })
-- Normal mode center next selection
map("n", "n", "nzz", { desc = "Move to next search result and center line." })
map("n", "N", "Nzz", { desc = "Move to Previous search result and center line." })

map("n", "x", '"_x', { desc = "Delete the char under cursor to void in normal mode" })
map("v", "x", '"_x', { desc = "Delete the char cursor to void in visual mode" })
-- Format pasted line
map("n", "p", "p==", { desc = "Auto formats / indents the pasted text" })
-- Save file
map("n", "<C-s>", ":w<CR>", { desc = "Saves current buffer" })
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
-- New buffer
map("n", "<leader>bn", ":enew<CR>", { desc = "Create new buffer" })

-- Windows movement
map_for_modes({ "n", "t", "v" }, "<C-h>", "<C-w>h", { desc = "Move to Left Window" })
map_for_modes({ "n", "t", "v" }, "<C-j>", "<C-w>j", { desc = "Move to Down Window" })
map_for_modes({ "n", "t", "v" }, "<C-k>", "<C-w>k", { desc = "Move to Top Window" })
map_for_modes({ "n", "t", "v" }, "<C-l>", "<C-w>l", { desc = "Move to Right Window" })

-- Disable arrow keys
-- map("n", "<Left>", ":echomsg 'Use h'<CR>", { desc = "Disable Left Arrow Key" })
-- map("n", "<Right>", ":echomsg 'Use l'<CR>", { desc = "Disable Right Arrow Key" })
-- map("n", "<Up>", ":echomsg 'Use k'<CR>", { desc = "Disable Up Arrow Key" })
-- map("n", "<Down>", ":echomsg 'Use j'<CR>", { desc = "Disable Down Arrow Key" })

-- Lazy keymaps
map("n", "<leader>lo", "<Cmd>Lazy<CR>", { desc = "Lazy - Open" })
map("n", "<leader>lu", "<Cmd>Lazy update<CR>", { desc = "Lazy - Update" })
map("n", "<leader>ls", "<Cmd>Lazy sync<CR>", { desc = "Lazy - Sync" })
map("n", "<leader>lh", "<Cmd>Lazy health<CR>", { desc = "Lazy - Health" })
map("n", "<leader>l?", "<Cmd>Lazy help<CR>", { desc = "Lazy - Help" })
map("n", "<leader>li", "<Cmd>Lazy install<CR>", { desc = "Lazy - Install " })
map("n", "<leader>lc", "<Cmd>Lazy clean<CR>", { desc = "Lazy - Clean " })
