-- indent-blankline configuration

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {},
  -- Change the color of the indent line
  config = function()
    require("ibl").setup({
      enabled = true,
      debounce = 100,
      viewport_buffer = { min = 30 },
      indent = {
        char = "▏",
        smart_indent_cap = true,
        priority = 1,
        repeat_linebreak = false,
        highlight = "IndentBlanklineChar",
      },
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
        show_exact_scope = true,
        injected_languages = true,
        priority = 500,
        highlight = "IndentBlanklineContextChar",
        include = { node_type = { lua = { "table_constructor" } } },
        exclude = {},
      },
      -- List of filetypes to disable indent-blankline
      exclude = {},
    })
  end,
}
