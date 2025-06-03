return {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  -- optional for icon support
  dependencies = {
    -- "nvim-tree/nvim-web-devicons",
    "echasnovski/mini.icons",
    "junegunn/fzf",
    -- build = "./install --bin",
  },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({
      winopts = {
        -- split = "belowright 20new",

        preview = {
          -- default = "bat", -- override the default previewer?
          -- default uses the 'builtin' previewer
          border = "rounded",  -- preview border: accepts both `nvim_open_win`
          wrap = false,        -- preview line wrap (fzf's 'wrap|nowrap')
          hidden = false,      -- start preview hidden
          vertical = "down:45%", -- up|down:size
          horizontal = "right:60%", -- right|left:size
          layout = "flex",     -- horizontal|vertical|flex
          -- layout = "horizontal", -- horizontal|vertical|flex
          flip_columns = 100,  -- #cols to switch to horizontal on flex
          -- Only used with the builtin previewer:
          title = true,        -- preview border title (file/buf)?
          title_pos = "center", -- left|center|right, title alignment
          scrollbar = "false", -- `false` or string:'float|border'
          -- float:  in-window floating border
          -- border: in-border "block" marker
          scrolloff = -1, -- float scrollbar offset from right
          -- applies only when scrollbar = 'float'
          delay = 20, -- delay(ms) displaying the preview
          -- prevents lag on fast scrolling
          winopts = { -- builtin previewer window options
            number = true,
            relativenumber = false,
            cursorline = true,
            cursorlineopt = "both",
            cursorcolumn = false,
            signcolumn = "no",
            list = false,
            foldenable = false,
            foldmethod = "manual",
          },
        },
      },
    })
  end,

  -- Key mappings
  vim.api.nvim_set_keymap(
    "n",
    "<leader>ff",
    ":lua require('fzf-lua').files()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find files" }
  ),
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fg",
    ":lua require('fzf-lua').live_grep()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find grep" }
  ),
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fb",
    ":lua require('fzf-lua').buffers()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find buffers" }
  ),
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fh",
    ":lua require('fzf-lua').help_tags()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find help tags" }
  ),
  -- Search project level
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fp",
    ":lua require('fzf-lua').grep_project()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find project" }
  ),
  -- Search for keyword under cursor
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fk",
    ":lua require('fzf-lua').grep_cword()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find keyword" }
  ),
  vim.api.nvim_set_keymap(
    "n",
    "<leader>fq",
    ":lua require('fzf-lua').grep_quickfix()<CR>",
    { noremap = true, silent = true, desc = "Fuzzy find quickfix" }
  ),

  vim.api.nvim_set_keymap(
    "n",
    "<leader>fr",
    ":lua require('fzf-lua').resume()<CR>",
    { noremap = true, silent = true, desc = "Resume fuzzy find" }
  ),

  vim.api.nvim_set_keymap(
    "n",
    "<leader>fm",
    ":lua require('fzf-lua').keymaps()<CR>",
    { noremap = true, silent = true, desc = "Display keymaps" }
  ),
}
