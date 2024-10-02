-- harpoon.nvim
return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },

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
		map("<leader>1", function()
			harpoon:list():select(1)
		end, { desc = "Harpoon select 1st file" })
		map("<leader>2", function()
			harpoon:list():select(2)
		end, { desc = "Harpoon select 2nd file" })
		map("<leader>3", function()
			harpoon:list():select(3)
		end, { desc = "Harpoon select 3rd file" })
		map("<leader>4", function()
			harpoon:list():select(4)
		end, { desc = "Harpoon select 4th file" })
	end,
}
