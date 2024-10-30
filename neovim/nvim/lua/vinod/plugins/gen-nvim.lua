-- Custom Parameters (with default
-- Define the map function
local function map(modes, lhs, rhs, desc)
	local options = { noremap = true, silent = true, desc = desc }
	for _, mode in ipairs(modes) do
		vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	end
end

-- Select Ollama Model (Wrapper function aroung Gen.select_model)
local function select_ollama_model()
	local gen = require("gen")
	gen.select_model()

	print("Selected model from gen: ", gen.model)
	-- how will this work?
	-- local gen_config = require("vinod.plugins.gen-nvim")
	-- -- update model here.
	-- gen_config.opts.model = gen.model
	-- refresh lualine
	require("lualine").refresh()
end

return {
	"David-Kunz/gen.nvim",
	opts = {
		model = "qwen2.5:7b", -- The default model to use.
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
	-- User Commands for selecting Ollama Model
	vim.api.nvim_create_user_command("SelectOllamaModel", select_ollama_model, {}),
	--Keymaps
	map({ "n", "v" }, "<leader>op", ":Gen<CR>", "Ollama Prompts"),
	map({ "n", "v" }, "<leader>ol", ":SelectOllamaModel<Cr>", "Ollama List Models"),
	-- map({ "n", "v" }, "<leader>ol", ":lua require('gen').select_model()<Cr>", "Ollama List Models"),
}
