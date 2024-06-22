--luasnip.c.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local extras = require("luasnip.extras")
local rep = extras.rep
local fmt = require("luasnip.extras.fmt").fmt
local c = ls.choice_node

-- C Snippets
ls.add_snippets("c", {
    -- Function template
	s(
		"fn",
		fmt([[
    {returnType} {name} ({params}) {{
        {body}
        return {returnValue}
   }}
   ]], {
        returnType = i(1, "return_type"),
        name = i(2, "function_name"),
        params = i(3, "parameters"),
        returnValue = i(4, "0"),
        body = i(5, "function_body")
	})),

    -- Main function
    s(
		"main",
		fmt([[
    int main (int argc, char *argv[]) {{
        {body}
        return 0;
   }}
   ]], {
        body = i(0, "function_body")
	})),
})
