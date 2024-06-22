-- /lua/vinod/plugins/luasnip/snips.lua
--
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.add_snippets("lua", { s("h", t("Hello World")) })

