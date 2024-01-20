-- init.lua
-- Vinod Nair MD
-- 12-6-2024
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=802s
--


vim.g.mapleader = ","
vim.g.localleader = ";"

require("vinod.keymaps")
require("vinod.options")
require("vinod.lazy-config")
-- Plugin config files.
require("vinod.whichkey")


