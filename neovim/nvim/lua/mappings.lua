-- mappings.lua

local map = vim.api.nvim_set_keymap
local options = { noremap = true }
local cmd_options = { noremap = true, silent = true }

vim.g.mapleader = ','
vim.g.localleader = ';'

map("n", "<Esc>", ":nohl<CR><Esc>", cmd_options)
