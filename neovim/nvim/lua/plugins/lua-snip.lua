-- LuaSnip installation and configuration

return {

    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    event = "InsertEnter",
    config = function()
      --  Luasnip configuration
       local ls = require("luasnip")
       vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end,
         {silent = true, desc = "Expand LuaSnip snippet"})
       vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump(1) end,
         {silent = true, desc = "Jump to next LuaSnip snippet position"})
       vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end,
         {silent = true, desc = "Jump to previous LuaSnip snippet position"})
       vim.keymap.set({"i", "s"}, "<C-E>", function()
         if ls.choice_active() then
           ls.change_choice(1)
         end
       end, {silent = true, desc = "Cycle through LuaSnip choices"})

    end


}
