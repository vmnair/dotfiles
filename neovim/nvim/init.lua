-- init.lua
-- Vinod Nair MD
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=30s

require("vinod.config.lazy")
require("vinod.config.options")
require("vinod.config.util")
require("vinod.config.autocmds")
require("vinod.config.aliases")
-- require("vinod.config.mappings") Called from lazy.lua

vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/dev-plugins/readwise.nvim")
