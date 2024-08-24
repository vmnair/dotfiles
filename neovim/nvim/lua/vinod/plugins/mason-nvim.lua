return {
  "williamboman/mason.nvim",
  event = "VeryLazy",
  config = function()
    require("mason").setup({
      -- UI
      ui = {
        border = "rounded",
        width = 0.6,
        height = 0.6,
        require("mason").setup({
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        }),
      },
    })
  end,
}
