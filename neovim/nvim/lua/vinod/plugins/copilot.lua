-- Github Copilot
vim.g.copilot_no_tab_map = true
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<Tab>",
          refresh = "gr",
          open = "<M-CR>",
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 10,
        -- keymap = {
        --   accept = "<M-l>",
        --   next = "<M-]>",
        --   prev = "<M-[>",
        --   dismiss = "<C-]>",
        -- },
      },
      -- Explain this to me
      filetypes = {
        c = true,
        lua = true,
        rust = true,
        go = true,
        ["."] = false,            -- disable foe all other filetypes
      },
      copilot_node_command = "node", -- Node.js version must be > 17.x
      server_opts_overrides = {},
    })
  end,
}
