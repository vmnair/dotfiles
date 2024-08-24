return {
  "lervag/vimtex",
  ft = "tex",
  lazy = true,
  config = function()
    -- comment out for debugging purposes
    vim.g.vimtex_log_verbose = 1
    vim.g.vimtex_view_verbose = 1
    -- Set Zathura as the view method
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_quickfix_mode = 0
    vim.g.tex_flavor = "latex"
    -- vim.g.vimtex_view_method = "skim"
    -- --vim.g.vimtext_view_general_options = "--keep-focus"
    -- vim.g.vimtex_view_general_options = "--unique file:@pdf\\#src:@line@tex --keep-focus"
    -- vim.g.vimtex_view_skim_sync = 1
    -- vim.g.vimtex_view_skim_activate = 0 -- Do not activate skim
    -- vim.g.vimtex_view_skim_reading_bar = 0
    -- vim.g.vimtex_compiler_latexmk = {
    --   options = {
    --     "-pdf",
    --     "-shell-escape",
    --     "-verbose",
    --     "-file-line-error",
    --     "-synctex=1",
    --     "-interaction=nonstopmode",
    --   },
    -- }
    -- vim.g.vimtex_compiler_method = "latexmk" -- LaTeX compiler
    -- vim.g.vimtex_compiler_latexmk.continous = 0
  end,
}
