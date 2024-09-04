return {
	"lervag/vimtex",
	ft = "tex",
	lazy = true,
	config = function()
		-- Set Zathura as the view method
		vim.g.tex_flavor = "latex"
		vim.g.vimtex_view_method = "skim"
		-- Enable quickfix mode for Latex errors
		vim.g.vimtex_quickfix_mode = 1
		vim.opt.conceallevel = 1
		-- specify what to conceal
		-- a:accents b:bold text d:delimiters m:math g:greek letters
		vim.g.tex_conceal = "abdmg"
		vim.g.vimtex_compiler_method = "latexmk"
		-- comment out for debugging purposes
		vim.g.vimtex_log_verbose = 1
		vim.g.vimtex_view_verbose = 1
		-- Key mappings
		vim.api.nvim_set_keymap(
			"n",
			"<leader>ll",
			":VimtexCompile<CR>",
			{ noremap = true, silent = true, desc = "Compile Latex" }
		)
		vim.api.nvim_set_keymap(
			"n",
			"<leader>lv",
			":VimtexView<CR>",
			{ noremap = true, silent = true, desc = "View Latex" }
		)
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
