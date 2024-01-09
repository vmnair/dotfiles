-- init.lua
-- Vinod Nair MD
-- 12-6-2024
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=802s
--
-- Set local leader
vim.g.mapleader = ','
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")

-- Bootstrap lazy.nvim starts
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
-- Bootstrap lazy.nvim ends

-- Load plugins
require("lazy").setup("plugins")
 
