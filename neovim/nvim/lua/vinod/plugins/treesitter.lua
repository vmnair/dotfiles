-- treesitter.lua

return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	build = ":TSUpdate", -- update parsers using this command,
	event = "VeryLazy",
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			ensure_enabled = {
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"go",
				"markdown",
				"markdown_inline",
				"latex",
				"cmake",
			},
			-- automatically install parser if a new filetype has none.
			auto_install = true,
			sync_install = false,
			highlight = {
				enable = true,
				-- disable treesitter for large files.
				disable = function(lang, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
				-- disble regex based highlighting for vim.
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					node_incremental = "<Tab>",
					node_decremental = "<BS>",
					scope_incremental = "<S-Tab>",
				},
			},
			-- Set up textobjects
			textobjects = {
				select = {
					enable = true,
					lookahead = true, --improves functionality
					keymaps = {
						-- you can use the capture groups defined in textobjects.scm
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["aa"] = "@parameter.outer", -- "around argument"
						["ia"] = "@parameter.inner", -- "inside argument"
						["ab"] = "@block.outer", -- "around block"
						["ib"] = "@block.inner", -- "inside block"
						-- you can optionally set descriptions to the mappings (used in the desc parameter of
						-- nvim_buf_set_keymap) which plugins like which-key display
						["ic"] = { query = "@class.inner", desc = "select inner part of a class region" },
						-- you can also use captures from other query groups like `locals.scm`
						["as"] = { query = "@scope", query_group = "locals", desc = "select language scope" },
					},
					-- you can choose the select mode (default is charwise 'v')
					--
					-- can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * method: eg 'v' or 'o'
					-- and should return the mode ('v', 'v', or '<c-v>') or a table
					-- mapping query_strings to modes.
					selection_modes = {
						["@parameter.outer"] = "v", -- charwise
						["@function.outer"] = "v", -- linewise
						["@class.outer"] = "<c-v>", -- blockwise
					},
					-- if you set this to `true` (default is `false`) then any textobject is
					-- extended to include preceding or succeeding whitespace. succeeding
					-- whitespace has priority in order to act similarly to eg the built-in
					-- `ap`.
					--
					-- can also be a function which gets passed a table with the keys
					-- * query_string: eg '@function.inner'
					-- * selection_mode: eg 'v'
					-- and should return true or false
					include_surrounding_whitespace = true,
				},
			},
		})
	end,
}
