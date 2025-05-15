return {
  "zk-org/zk-nvim",
  config = function()
    require("zk").setup({
      -- See Setup section below
      picker = "fzf_lua",
      lsp = {
        -- `config` is passed to `vim.lsp.start_client(config)`
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start_client()`
        },
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })
  end,
}
