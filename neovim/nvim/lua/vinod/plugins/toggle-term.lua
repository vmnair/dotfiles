-- toggleterm.lua
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("toggleterm").setup({
      open_mapping = "<leader>tt",
      insert_mapping = true, -- Mappings active in insert mode.
      autochdir = true,   -- Sync with Neovim directory
    })

    -- Set keymaps function
    function _G.set_terminal_keymaps()
      local opts = { noremap = true, silent = true }
      local map = vim.api.nvim_buf_set_keymap
      map(0, "t", "<esc>", [[<c-\><c-n>]], opts) -- escape -> normal mode
    end

    -- Set keymaps using the above function
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

    -- Keymap to set floating terminal
    local modes = { "n", "i" }
    for _, mode in ipairs(modes) do
      vim.api.nvim_set_keymap(
        mode,
        "<leader>tf",
        "<Cmd>ToggleTerm direction=float<CR>",
        { noremap = true, silent = true, desc = "Floating Terminal" }
      )

      -- Keymap to hide floating terminal
      vim.api.nvim_set_keymap(
        "n",
        "<leader>th",
        "<Cmd>ToggleTerm<CR>",
        { noremap = true, silent = true, desc = "Hide Floating Terminal" }
      )
    end
  end, -- function config ends
}
