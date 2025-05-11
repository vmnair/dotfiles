-- init.lua
-- Vinod Nair MD
-- https://www.youtube.com/watch?v=zHTeCSVAFNY&t=30s
require("vinod.config.lazy")
require("vinod.config.options")
require("vinod.config.util")
require("vinod.config.autocmds")
require("vinod.config.aliases")
-- require("vinod.config.mappings") Called from lazy.lua

--
-- Enable [[ to trigger the completion menu in markdown files
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     if vim.lsp.omnifunc then
--       -- Set the omnifunc to the LSP's omnifunc
--       vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
--       -- Create a buffer-local mapping for [[ to trigger completion
--       vim.api.nvim_buf_set_keymap(0, "i", "[[", "[[<C-x><C-o>", { noremap = true, silent = true })
--     else
--       vim.notify("LSP omnifunc not available", vim.log.levels.WARN)
--     end
--     -- assign the omnifunc of  lsp to local buffer (markdown filetype)
--     -- vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
--   end,
-- })
