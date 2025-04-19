-- Plugin: lervag/vimtex
-- Author: Vinod Nair

-- Local utility functions.

-- Detect the OS and set the vimtex_view_method accordingly
local os_type = require("vinod.config.util").detect_os()
if os_type == "Darwin" then
	-- print("vinod.debug MacOSX Detected: Setting Skim as the PDF Viewer")
	vim.g.vimtex_view_method = "skim"
elseif os_type == "Linux" then
	-- print("vinod.debug Linux Detected: Setting Zathura as the PDF Viewer")
	vim.g.vimtex_view_method = "zathura"
else
	print("Error: Unsupported OS\nModule: vimtex.lua")
	return
end

return {
	"lervag/vimtex",
	ft = "tex",
	event = "VeryLazy",
	-- lazy = false,
	config = function()
		vim.g.tex_flavor = "latex"
		-- Enable quickfix mode for Latex errors
		vim.g.vimtex_quickfix_mode = 1
		vim.g.vimtex_quickfix_open_on_warning = 1 --  don't open quickfix if there are only warnings

		vim.opt.conceallevel = 1
		-- specify what to conceal
		-- a:accents b:bold text d:delimiters m:math g:greek letters
		vim.g.tex_conceal = "abdmg"

		-- Use latxmk for compiling
		-- http://users.phys.psu.edu/~collins/software/latexmk-jcc
		vim.g.vimtex_compiler_method = "latexmk"
		-- Debugging purposes
		-- vim.g.vimtex_log_verbose = 1
		-- vim.g.vimtex_view_verbose = 1

		-- Key mappings
		-- Set via autocmds
	end,
}
