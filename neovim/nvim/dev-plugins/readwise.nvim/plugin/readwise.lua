-- lua/plugin/readwise.lua
-- File starts automatically when neovim starts

-- Prevent loading the plugin more than once
print("Loading Readwise Plugin")
if vim.g.readwise_loaded == 1 then
  return
end

vim.g.readwise_loaded = 1

vim.api.nvim_create_user_command("ReadwiseTest", function()
  print("Readwise Test Command Executed")
  require("readwise").test()
end, { desc = "Test if Readwise plugin is working" })
