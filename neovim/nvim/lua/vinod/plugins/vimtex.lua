return {
	"lervag/vimtex",
	config = function()
		vim.g.vimtex_view_method = "skim"
		vim.g.vimtex_compiler_method = "latexmk" -- LaTeX compiler
	end,
}
