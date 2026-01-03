return {
	"ibhagwan/fzf-lua",
	event = "VeryLazy",
	-- optional for icon support
	dependencies = {
		-- "nvim-tree/nvim-web-devicons",
		"echasnovski/mini.icons",
	},
	config = function()
		-- calling `setup` is optional for customization
		require("fzf-lua").setup({
			defaults = {
				formatter = "path.filename_first", -- display filename before the file path
			},
			hls = {
				path_dirname = "Comment", -- light gray
			},
			files = {
				formatter = "path.filename_first", -- display filename before the file path
			},
			grep = {
				cmd = "rg --vimgrep",
				multiprocess = true, -- run command in a separate process
				file_icons = true, -- show file icons
				color = "always", -- colorize output
				git_icons = true, -- show git status icons
				silent = true, -- hide auto-detection messages
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
			},
			winopts = {
				-- split = "belowright 20new",
				border = "rounded",
				backdrop = 80,
				treesitter = {
					enabled = true,
					fzf_colors = { ["hl"] = "-1:reverse", ["hl+"] = "-1:reverse" },
				},
				preview = {
					-- default = "bat", -- override the default previewer?
					-- default uses the 'builtin' previewer
					border = "rounded", -- preview border: accepts both `nvim_open_win`
					wrap = false, -- preview line wrap (fzf's 'wrap|nowrap')
					hidden = false, -- start preview hidden
					vertical = "down:45%", -- up|down:size
					horizontal = "right:60%", -- right|left:size
					layout = "flex", -- horizontal|vertical|flex
					-- layout = "horizontal", -- horizontal|vertical|flex
					flip_columns = 100, -- #cols to switch to horizontal on flex
					-- Only used with the builtin previewer:
					title = true, -- preview border title (file/buf)?
					title_pos = "center", -- left|center|right, title alignment
					scrollbar = "false", -- `false` or string:'float|border'
					-- float:  in-window floating border
					-- border: in-border "block" marker
					scrolloff = -1, -- float scrollbar offset from right
					-- applies only when scrollbar = 'float'
					delay = 20, -- delay(ms) displaying the preview
					-- prevents lag on fast scrolling
					winopts = { -- builtin previewer window options
						number = true,
						relativenumber = false,
						cursorline = true,
						cursorlineopt = "both",
						cursorcolumn = false,
						signcolumn = "no",
						list = false,
						foldenable = false,
						foldmethod = "manual",
					},
				},
			},
		})
	end,

	-- Key mappings (temporarily reverted to test fg error)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>ff",
		":lua require('fzf-lua').files()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find files" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fg",
		":lua require('fzf-lua').live_grep()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find grep" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fc",
		":lua require('fzf-lua').lgrep_curbuf()<CR>",
		{ noremap = true, silent = true, desc = "[F]ind in [C]urrent buffer" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fb",
		":lua require('fzf-lua').buffers()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find buffers" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fh",
		":lua require('fzf-lua').help_tags()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find help tags" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fp",
		":lua require('fzf-lua').grep_project()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find project" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fw",
		":lua require('fzf-lua').grep_cword()<CR>",
		{ noremap = true, silent = true, desc = "F[ind] current [w]ord" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fW",
		":lua require('fzf-lua').grep_cWORD()<CR>",
		{ noremap = true, silent = true, desc = "F[ind] current [W]ORD" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fo",
		":lua require('fzf-lua').oldfiles()<CR>",
		{ noremap = true, silent = true, desc = "F[ind] old files" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fa",
		":lua require('fzf-lua').autocmds()<CR>",
		{ noremap = true, silent = true, desc = "F[ind] autocmds" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>gs",
		":lua require('fzf-lua').git_status()<CR>",
		{ noremap = true, silent = true, desc = "[g]it [s]tatus" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fq",
		":lua require('fzf-lua').grep_quickfix()<CR>",
		{ noremap = true, silent = true, desc = "Fuzzy find quickfix" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fr",
		":lua require('fzf-lua').resume()<CR>",
		{ noremap = true, silent = true, desc = "Resume fuzzy find" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>fm",
		":lua require('fzf-lua').keymaps()<CR>",
		{ noremap = true, silent = true, desc = "Display keymaps" }
	),

	vim.api.nvim_set_keymap(
		"n",
		"<leader>fig",
		":lua require('fzf-lua').files({ cwd = vim.fn.stdpath('config')})<CR>",
		{ noremap = true, silent = true, desc = "Display keymaps" }
	),
}
