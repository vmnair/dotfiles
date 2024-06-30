return {
  "folke/tokyonight.nvim",

  lazy = false,
  priority = 1000,
  opts = {},

  config = function()
    -- Setup function
    require("tokyonight").setup({
        style = "night", -- storm, day, moon and night
        terminal_colors = true,

        styles = {
            comments = { italic = true },
            keywords = { italic = false },
            functions =  { italic = false },
            variables = { italic = false },
        }
    })
    -- set the colorscheme
    vim.cmd[[colorscheme tokyonight]]
  end,

}
