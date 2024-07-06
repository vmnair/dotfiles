-- mappings.lua

--[[
-- This function adds ability ti add desc to local options which has
-- noremap and silent.
--]]
local map = function(mode, lhs, rhs, opts)
  local options = {noremap = true, silent = true}
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

map("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
map("n", "<Esc>", ":nohl<CR><Esc>", {desc = "Clear search highlights"})
                                      -- Normal mode center next selection
map("n", "n", "nzz", {desc = "Move to next search result and center line."})
map("n", "N", "Nzz", {desc = "Move to Previous search result and center line."})

map("n", "x", '"_x', {desc = "Delete the char under cursor to void in normal mode"})
map("v", "x", '"_x', {desc = "Delete the char cursor to void in visual mode"})
-- Format pasted line
map("n", "p", "p==", {desc = "Auto formats / indents the pasted text"})
-- Save file
map("n", "<C-s>", ":w<CR>", {desc = "Saves current buffer"})
-- Vertical split
map("n", "<leader>+", "<Cmd>vsplit<CR>", {desc = "Splits vertically"})
-- Horizontal split
map("n", "<leader>-", "<Cmd>split<CR>", {desc = "Splits horizondally"})
-- Resize splits
map("n", "<S-Left>", "<Cmd>vertical resize -2<CR>", {desc = "Resize pane vertically"})
map("n", "<S-Right>", "<Cmd>vertical resize +2<CR>", {desc = "Resize pane vertically"})
map("n", "<S-Up>", "<Cmd>resize -2<CR>", {desc = "Resize pane up"})
map("n", "<S-Down>", "<Cmd>resize +2<CR>", {desc = "Resize pane down"})
-- Indent/Unindent selected text with Tab and Shift+Tab
map("v", ">", ">gv", {desc = "Indent selected line to right"})
map("v", "<", "<gv", {desc = "Indent selected line to left"})
-- New buffer
map("n", "<leader>bn", ":enew<CR>", {desc = "Create new buffer"})

-- See all TODO's in a quicklist
-- TODO Check this out
map("n", "<leader>st", ":grep -l TODO **/*<CR>:copen<CR>", {desc = "Search for TODO's"})

