return {
	"dustinblackman/oatmeal.nvim",
	cmd = { "Oatmeal" },
	keys = {
		{ "<leader>om", mode = { "n", "v" }, desc = "Oatmeal session" },
	},
	opts = {
		backend = "ollama",
		-- model = "gemma3:27b",
		model = "codellama:7b",
	},
}
