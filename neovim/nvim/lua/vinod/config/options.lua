-- vim-options.lua


vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wrap = false

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- Synchronizes the system clipboard with
-- Neovim's clipboard.
vim.opt.clipboard= "unnamedplus"

-- Places cursor in the middle of the screen
vim.opt.scrolloff = 999

vim.opt.colorcolumn = "80"
vim.opt.signcolumn = 'yes'

vim.opt.showmode = false
vim.opt.showmatch = true

-- Ability to select cells where there are no
-- characters, we will set it to only in 
-- block mode.
vim.opt.virtualedit = "block"

-- Show incremental search in a split
vim.opt.inccommand = "split"

-- Ignore case sensitivity in commands
vim.opt.ignorecase = true

vim.opt.termguicolors = true
vim.opt.encoding = "utf-8"

-- Which-key
vim.opt.timeout = true
vim.opt.timeoutlen = 300
vim.opt.mouse = ''

