return {
  "iamcco/markdown-preview.nvim",
  event = "VeryLazy",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  keys = {
    {
      "<leader>mp",
      ft = "markdown",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Markdown preview",
    },
  },
  config = function()
    -- Custom function to open Chrome on macOS
    vim.api.nvim_exec2([[
      function! OpenMarkdownPreview(url)
        call system('open -a "Google Chrome" ' . shellescape(a:url))
      endfunction
    ]], {})
    vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'

    -- Enable mermaid diagram support
    vim.g.mkdp_preview_options = {
      maid = { theme = 'default' },
      disable_sync_scroll = 0,
      sync_scroll_type = 'middle',
    }

    -- Keep preview open when switching buffers
    vim.g.mkdp_auto_close = 0

    -- Manual start with ,mp (not auto-start)
    vim.g.mkdp_auto_start = 0

    vim.cmd([[do FileType]])
  end,
}
