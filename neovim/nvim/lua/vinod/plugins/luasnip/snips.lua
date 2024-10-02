-- /lua/vinod/plugins/luasnip/snips.lua
--
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

-- Lua Snippets
ls.add_snippets("lua", {
  s("h", t("Hello World")),
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

-- C Snippets
ls.add_snippets("c", {
  -- Function template
  s(
    "fn",
    fmt(
      [[
    {returnType} {name} ({params}) {{
        {body}
        return {returnValue}
   }}
   ]],
      {
        returnType = i(1, "return_type"),
        name = i(2, "function_name"),
        params = i(3, "parameters"),
        returnValue = i(4, "0"),
        body = i(5, "function_body"),
      }
    )
  ),

  -- Main function
  s(
    "main",
    fmt(
      [[
    int main (int argc, char *argv[]) {{
        {body}
        return 0;
   }}
   ]],
      {
        body = i(0, "function_body"),
      }
    )
  ),
})

-- Tex Snippets
ls.add_snippets("tex", {
  -- Document template
  s(
    "doc",
    fmt(
      [[
      \documentclass{{article}}
      \usepackage{{{}}}
      \title{{{}}}
      \author{{{}}}
      \date{{{}}}
      \begin{{document}}
      \maketitle
      {}
      \end{{document}}
      ]],
      {
        i(1, "amsmath"), -- Insert node for package
        i(2, "Title"), -- Insert node for title
        i(3, "Author"), -- Insert node for author
        i(4, "\\today"), -- Insert node for date
        i(5, "Content"), -- Insert node for document content
      }
    )
  ),
})
