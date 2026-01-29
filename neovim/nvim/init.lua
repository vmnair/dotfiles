-- init.lua
-- Vinod Nair MD
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=30s

require("vinod.config.lazy")
require("vinod.config.options")
require("vinod.config.util")
require("vinod.config.autocmds")
require("vinod.config.aliases")
require("vinod.config.c_dev")
require("vinod.config.lsp")
-- require("vinod.config.mappings") Called from lazy.lua
require("vinod.config.todo_commands")

vim.defer_fn(function()
	require("fzf-lua").register_ui_select()
end, 0)

vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/dev-plugins/readwise.nvim")
