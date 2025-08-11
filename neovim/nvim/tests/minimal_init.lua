-- Minimal init code for testing readwise plugin
-- Only sets up the necessary options and plugins

-- Add current directory to runtime path
vim.opt.rtp:prepend(".")

-- Bootstrap lazy.nvim for testing
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim with only plenary for testing
require("lazy").setup({
  {
    "nvim-lua/plenary.nvim",
    -- No lazy loading for tests - we need it immediately
    lazy = false,
  },
}, {
  -- Configure for testing environment
  install = { colorscheme = {} },
  checker = { enabled = false },         -- disable automatic update checks
  change_detection = { enabled = false }, -- disable automatic config reload
})

-- Set up specific configurations
vim.g.readwise_test_mode = true
