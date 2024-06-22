-- gitsigns.lua
return {
	"lewis6991/gitsigns.nvim",

	config = function()
		require("gitsigns").setup{
            on_attach = function(bufnr)
                local gitsigns = require('gitsigns')

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end
                map('n', '<leader>ghs', gitsigns.stage_hunk, {desc = "Stage hunk"})
            end
        }

	end,
}
