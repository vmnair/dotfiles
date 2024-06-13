-- mappings.lua

local map = vim.api.nvim_set_keymap
local options = { noremap = true }
local cmd_options = { noremap = true, silent = true }

vim.g.mapleader = ","
vim.g.localleader = ";"

-- Disable highlights on pressing <ESC>
map("n", "<Esc>", ":nohl<CR><Esc>", cmd_options)
-- Normal mode center next selection
map("n", "n", "nzz", options)
map("n", "N", "Nzz", options)
-- Deleting to the void
map("n", "x", '"_x', options)
map("v", "x", '"_x', options)
-- Format pasted line
map("n", "p", "p==", options)
-- Save file
map("n", "<C-s>", ":w<CR>", options)
-- Vertical split
map("n", "<leader>+", "<Cmd>vsplit<CR>", cmd_options)
-- Horizontal split
map("n", "<leader>-", "<Cmd>split<CR>", cmd_options)
-- Move in splits with hjkl (Terminal and Normal Mode)
map("n", "<leader>h", "<Cmd>wincmd h<CR>", cmd_options)
map("n", "<leader>j", "<Cmd>wincmd j<CR>", cmd_options)
map("n", "<leader>k", "<Cmd>wincmd k<CR>", cmd_options)
map("n", "<leader>l", "<Cmd>wincmd l<CR>", cmd_options)
map("t", "<leader>h", "<Cmd>wincmd h<CR>", cmd_options)
map("t", "<leader>j", "<Cmd>wincmd j<CR>", cmd_options)
map("t", "<leader>k", "<Cmd>wincmd k<CR>", cmd_options)
map("t", "<leader>l", "<Cmd>wincmd l<CR>", cmd_options)
-- Resize splits
map("n", "<S-Left>", "<Cmd>vertical resize -2<CR>", options)
map("n", "<S-Right>", "<Cmd>vertical resize +2<CR>", options)
map("n", "<S-Up>", "<Cmd>resize -2<CR>", options)
map("n", "<S-Down>", "<Cmd>resize +2<CR>", options)
-- Indent/Unindent selected text with Tab and Shift+Tab
map("v", ">", ">gv", options)
map("v", "<", "<gv", options)
-- New buffer
map("n", "<leader>bn", ":enew<CR>", cmd_options)
-- Next buffer
map("n", "<Tab>", "<Cmd>bnext<CR>", cmd_options)
-- Previous buffer
map("n", "<S-Tab>", "<Cmd>bprevious<CR>", cmd_options)
-- Quit current buffer
map("n", "<leader>bq", "<Cmd>bd<CR>", cmd_options)

-- See all TODO's in a quicklist
-- TODO Check this out
map("n", "<leader>st", ":grep -l TODO **/*<CR>:copen<CR>", cmd_options)

-- Lazy git in telescope 
map("n", "<leader>lg", "<Cmd>Telescope<CR>", cmd_options)
