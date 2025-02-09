-- harpoon.nvim
return {
<<<<<<< HEAD
	"ThePrimeagen/harpoon",
	event = "VeryLazy",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
=======
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
>>>>>>> 851b830545db38bb37aa5587b3ef11e8a723fdf7

  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()
    local function map(lhs, rhs, opts)
      vim.keymap.set("n", lhs, rhs, opts or {})
    end

    map("<leader>ha", function()
      harpoon:list():add()
    end, { desc = "Harpoon add file" })
    map("<leader>hh", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon toggle quick menu" })
  end,
}
