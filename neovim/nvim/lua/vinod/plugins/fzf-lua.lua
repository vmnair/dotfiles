return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "junegunn/fzf",
    build = "./install --bin",
  },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({})
  end,
}
