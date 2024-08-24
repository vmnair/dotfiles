-- Github Copilot
return {

  "github/copilot.vim",
  -- what is wrong with this code snippet? It's not working
  config = function()
    -- What other default options do we have here?
    vim.g.copilot_filetypes = {
      xml = false,
      markdown = false,
    }
  end,
}
