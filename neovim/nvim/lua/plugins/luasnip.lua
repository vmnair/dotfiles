-- luasnip.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local extras = require("luasnip.extras")
local rep = extras.rep
local fmt = require("luasnip.extras.fmt").fmt
local c = ls.choice_node

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

ls.add_snippets("c", {
	s(
		"fn",
		fmt([[
    ${returnType} ${name} (${params}) {{
        ${body}
        return ${returnValue}
   }}
   ]], {
        returnType = i(1, "return_type"),
        name = i(2, "function_name"),
        params = i(3, "parameters"),
        returnValue = i(4, "0"),
        body = i(5, "function_body")
	})),
})

ls.add_snippets("lua", {
	s("fn", {
		t("function "),
		i(1, "name"),
		t("("),
		i(2, "parameters"),
		t(")"),
		t({ "", "\t" }),
		i(3),
		t({ "", "end" }),
	}),
})

-- TODO: Need to check why we are returning an empty table.
return {}
