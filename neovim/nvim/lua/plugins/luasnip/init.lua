-- luasnip.lua

local ls = require("luasnip")

-- Add Snippet files here.
require("plugins.luasnip.c")
require("plugins.luasnip.lua")

-- Keybindings
local map = vim.keymap.set
map({ "i", "s" }, "<C-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })

map({ "i", "s" }, "<C-j>", function()
	if ls.expand_or_jumpable(-1) then
		ls.expand_or_jump(-1)
	end
end, { silent = true })



-- TODO: Need to check why we are returning an empty table.
return {}
