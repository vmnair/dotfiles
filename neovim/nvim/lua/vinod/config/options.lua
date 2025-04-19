-- vim-options.lua

-- Disable various Neovim providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

local opt = vim.opt -- Conciseness

-- Do not be vi compatible
opt.compatible = false
opt.syntax = "on"

-- Add the current directory and its subdirectories to Vim's path
opt.path:append(".,**")
-- Wildmenu
opt.wildmenu = true

-- only show one line below the status line
opt.cmdheight = 1
opt.number = true
opt.relativenumber = true

opt.splitright = true --split horizontal window to below
opt.splitbelow = true -- split horizontal window to below

opt.wrap = false      -- disable line wrapping

opt.expandtab = true
opt.tabstop = 2               -- Expand tab to spaces
opt.shiftwidth = 2
opt.autoindent = true         -- Copy intent from the current line when starting new.

opt.textwidth = 80            -- Set the text width to 80 characters
opt.clipboard = "unnamedplus" -- Synchronizes the system clipboard

-- Places cursor in the middle of the screen
opt.scrolloff = 999
opt.cursorline = true -- Highlight current line.

opt.swapfile = false  -- Turn off swap file.

opt.showmode = false  -- Lualine does this, so we don't need it.
opt.showmatch = true

-- Ability to select cells where there are no
-- characters, we will set it to only in
-- block mode.
opt.virtualedit = "block"

opt.inccommand = "split" -- Show incremental search in a split
opt.ignorecase = true    -- Ignore case sensitivity in commands
opt.smartcase = true     -- Mixed case in search assumes case sensitivity.

opt.termguicolors = true -- Use true colors
opt.background = "dark"  -- Color schemes (light or dark) will be made dark.
opt.colorcolumn = "80"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start" -- Allow backspace on insert mode start.

opt.encoding = "utf-8"

-- opt.foldmethod = "indent"
-- Which-key
opt.timeout = true
opt.timeoutlen = 300
opt.mouse = ""

-- Set spell check
-- opt.spell = true
-- opt.spelllang = { "en" }
