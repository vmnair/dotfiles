-- lua.vinod.config.lazy.lua
-- Lazy.nvim boot-strapping

-- Mapleader should be set before Lazy setup so mappings work properly.
vim.g.mapleader = ","
vim.g.localleader = ";"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = "vinod.plugins",
	install = { colorscheme = { "tokyonight" } }, -- Colorscheme during install
	checker = { enabled = true }, --Automatically check for updates
})
-- call mappings after plugins are loaded
require("vinod.config.mappings")
