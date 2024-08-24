-- whichkey.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {}, -- default options
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer local keymaps (which-key)",
    },
  },
}
