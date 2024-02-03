-- treesitter.lua

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()

    -- Treesetter 
    local config = require("nvim-treesitter.configs")
    config.setup({
      --ensure_enabled = {"c", "lua", "python"},
      auto_install = true,
      sync_install   = false,
      highlight = {enable = true},
      indent = {enable = true},
    })
  end

}
