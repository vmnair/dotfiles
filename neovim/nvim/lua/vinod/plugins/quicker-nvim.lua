-- quicker.nvim
return {
  "stevearc/quicker.nvim",
  event = "VeryLazy",
  ---@module "quicker"
  ---@type quicker.SetupOptions
  opts = {
    -- Plugin specific keymaps. only be activated in a quickfix window.
    keys = {
      {
        ">",
        function()
          require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
        end,
        desc = "Expand quickfix context",
      },
      {
        "<",
        function()
          require("quicker").collapse()
        end,
        desc = "Collapse quickfix context",
      },
    },
  },
  -- Global key mappings
  keys = {
    {
      "<leader>qt",
      function()
        require("quicker").toggle()
      end,
      desc = "Toggle quickfix",
    },
  },
}
