-- Vinod Nair MDinitinit
-- init.lua
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=30s

-- explicitly set path to lua 5.1
vim.env.LUA_PATH = "/usr/local/share/lua/5.1/?.lua;;"
vim.env.LUA_CPATH = "/usr/local/lib/lua/5.1/?.so;;"


require("vim-options")
require("mappings")
require("vinod.config.lazy")
require("util")
