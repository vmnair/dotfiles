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
			fzf_tmux_opts = { ["-p"] = "80%,80%", ["--margin"] = "0,0" },
			-- Enhanced FZF options for better UI and performance
			fzf_opts = {
				["--ansi"] = "",
				["--info"] = "inline",
				["--height"] = "40%",
				["--layout"] = "reverse",
				["--border"] = "rounded",
				["--preview-window"] = "right:60%:wrap",
				["--bind"] = "ctrl-u:preview-page-up,ctrl-d:preview-page-down",
			},
			defaults = {
				formatter = "path.filename_first", -- display filename before the file path
			},
			-- Configure titles for different pickers
			files = {
				formatter = "path.filename_first",
				-- Exclude common directories for better performance
				find_opts = [[-type f -not -path '*/\.git/*' -not -path '*/node_modules/*' -not -path '*/\.next/*' -not -path '*/__pycache__/*' -not -path '*/target/*' -not -name '*.pyc' -not -name '*.o' -not -name '*.a' -not -name '*.so' -not -name '*.dylib' -not -name '.DS_Store']],
				rg_opts = "--files --hidden --follow --no-ignore-vcs -g '!{node_modules/*,.git/*,.next/*,__pycache__/*,target/*,*.pyc,*.o,*.a,*.so,*.dylib,.DS_Store,*.log}'",
				fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude .next --exclude __pycache__ --exclude target --exclude '*.pyc' --exclude '*.o' --exclude '*.a' --exclude '*.so' --exclude '*.dylib' --exclude .DS_Store",
			},
			grep = {
				cmd = "rg --vimgrep",
				multiprocess = true, -- run command in a separate process
				file_icons = true, -- show file icons
				color = "always", -- colorize output
				git_icons = true, -- show git status icons
				silent = true, -- hide auto-detection messages
				-- Enhanced ripgrep options with exclusions and hidden file support
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --follow --glob '!.git/*' --glob '!node_modules/*' --glob '!.next/*' --glob '!__pycache__/*' --glob '!target/*' --glob '!*.pyc' --glob '!*.o' --glob '!*.a' --glob '!*.so' --glob '!*.dylib' --glob '!.DS_Store' --glob '!*.log' --max-columns=4096",
				rg_glob = true, -- enable glob pattern support
			},
			hls = {
				path_dirname = "Comment", -- light gray
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

		-- Set up keymaps properly within config
		local fzf = require("fzf-lua")
		local keymap = vim.keymap.set
		local opts = { silent = true, remap = false }

		-- Core file operations
		keymap("n", "<leader>ff", fzf.files, vim.tbl_extend("force", opts, { desc = "Fuzzy find files" }))
		keymap("n", "<leader>fg", fzf.live_grep, vim.tbl_extend("force", opts, { desc = "Fuzzy find grep" }))

		keymap("n", "<leader>fc", fzf.lgrep_curbuf, vim.tbl_extend("force", opts, { desc = "[F]ind in [C]urrent buffer" }))
		keymap("n", "<leader>fb", fzf.buffers, vim.tbl_extend("force", opts, { desc = "Fuzzy find buffers" }))
		keymap("n", "<leader>fh", fzf.help_tags, vim.tbl_extend("force", opts, { desc = "Fuzzy find help tags" }))
		keymap("n", "<leader>fp", fzf.grep_project, vim.tbl_extend("force", opts, { desc = "Fuzzy find project" }))
		-- Word search operations
		keymap("n", "<leader>fw", fzf.grep_cword, vim.tbl_extend("force", opts, { desc = "F[ind] current [w]ord" }))
		keymap("n", "<leader>fW", fzf.grep_cWORD, vim.tbl_extend("force", opts, { desc = "F[ind] current [W]ORD" }))

		-- Additional operations
		keymap("n", "<leader>fo", fzf.oldfiles, vim.tbl_extend("force", opts, { desc = "F[ind] old files" }))
		keymap("n", "<leader>fa", fzf.autocmds, vim.tbl_extend("force", opts, { desc = "F[ind] autocmds" }))
		keymap("n", "<leader>gs", fzf.git_status, vim.tbl_extend("force", opts, { desc = "[g]it [s]tatus" }))
		keymap("n", "<leader>fq", fzf.grep_quickfix, vim.tbl_extend("force", opts, { desc = "Fuzzy find quickfix" }))
		keymap("n", "<leader>fR", fzf.resume, vim.tbl_extend("force", opts, { desc = "Resume fuzzy find" }))
		keymap("n", "<leader>fm", fzf.keymaps, vim.tbl_extend("force", opts, { desc = "Display keymaps" }))

		-- LSP integration
		keymap("n", "<leader>fs", fzf.lsp_document_symbols, vim.tbl_extend("force", opts, { desc = "Find symbols (document)" }))
		keymap("n", "<leader>fS", fzf.lsp_workspace_symbols, vim.tbl_extend("force", opts, { desc = "Find Symbols (workspace)" }))
		keymap("n", "<leader>fr", fzf.lsp_references, vim.tbl_extend("force", opts, { desc = "Find references" }))
		keymap("n", "<leader>fd", fzf.lsp_definitions, vim.tbl_extend("force", opts, { desc = "Find definitions" }))
		keymap("n", "<leader>fi", fzf.lsp_implementations, vim.tbl_extend("force", opts, { desc = "Find implementations" }))

		-- Specialized searches
		keymap("n", "<leader>fig", function()
			fzf.files({ cwd = vim.fn.stdpath("config") })
		end, vim.tbl_extend("force", opts, { desc = "View Neovim con[fig]" }))
	end,
}
