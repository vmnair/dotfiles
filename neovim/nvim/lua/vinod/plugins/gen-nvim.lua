-- gen-nvim.lua

-- Custom Parameters (with default
-- Define the map function
local function map(modes, lhs, rhs, desc)
	local options = { noremap = true, silent = true, desc = desc }
	for _, mode in ipairs(modes) do
		vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	end
end

-- Create the augroup and autocommand right after gen.nvim setup
local augroup = vim.api.nvim_create_augroup("LualineOllamaUpdate", { clear = true })

vim.api.nvim_create_autocmd("User", {
	pattern = "GenModelChanged",
	group = augroup,
	callback = function()
		require("lualine").refresh()
	end,
})

-- Setup the model change detection
local gen_select_model_original = nil
local function setup_model_change_detection()
	local ok, gen = pcall(require, "gen")
	if not ok then
		return
	end
	if not gen_select_model_original then
		gen_select_model_original = gen.select_model
	end
	gen.select_model = function(...)
		local result = gen_select_model_original(...)
		vim.api.nvim_exec_autocmds("User", { pattern = "GenModelChanged" })
		return result
	end
end

-- Call the Model Change Detection
setup_model_change_detection()

local function select_model()
	local handle = io.popen("ollama list")
	if not handle then
		return
	end
	local result = handle:read("*a")
	handle:close()
	local models = {}
	for line in result:gmatch("[^\r\n]+") do
		-- Skip the header line
		if not line:match("NAME") then
			-- Extract just the model name from the first column
			local model_name = line:match("^(%S+)")
			if model_name then
				table.insert(models, model_name)
			end
		end
	end

	-- Show model selection menu
	vim.ui.select(models, {
		prompt = "Select Ollama model:",
		format_item = function(item)
			return item
		end,
	}, function(model_name)
		if model_name then
			-- Update the runtime model
			local gen = require("gen")
			gen.model = model_name

			-- Notify user
			vim.notify("Switched to model: " .. model_name, vim.log.levels.INFO)

			-- Trigger our custom event for lualine update
			vim.api.nvim_exec_autocmds("User", { pattern = "GenModelChanged" })
		end
	end)
end

return {
	"David-Kunz/gen.nvim",
	opts = {
		model = "qwen2.5:latest", -- The default model to use.
		quit_map = "q", -- set keymap to close the response window
		retry_map = "<c-r>", -- set keymap to re-send the current prompt
		accept_map = "<c-cr>", -- set keymap to replace the previous selection with the last result
		host = "localhost", -- The host running the Ollama service.
		port = "11434", -- The port on which the Ollama service is listening.
		display_mode = "split", -- The display mode. Can be 'float' or 'split' or 'horizontal-split'.
		show_prompt = false, -- Shows the prompt submitted to Ollama.
		show_model = true, -- Displays which model you are using at the beginning of your chat session.
		no_auto_close = false, -- Never closes the window automatically.
		file = true, -- Write the payload to a temporary file to keep the command short.
		hidden = false, -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
		debug = false,

		init = function(options)
			pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
		end,
		-- Function to initialize Ollama
		command = function(options)
			local body = { model = options.model, stream = true }
			return "curl --silent --no-buffer -X POST http://"
				.. options.host
				.. ":"
				.. options.port
				.. "/api/chat -d $body"
		end,
	},

	-- User Commands
	vim.api.nvim_create_user_command("GenSelectModel", select_model, {}),
	map({ "n", "v" }, "<leader>op", ":Gen<CR>", "Ollama Prompts"),
	-- Create command and optional keybinding
	vim.keymap.set("n", "<leader>oo", ":GenSelectModel<CR>", { silent = true, desc = "Select Ollama model" }),
}
