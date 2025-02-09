return {
<<<<<<< HEAD
	"iamcco/markdown-preview.nvim",
	event = "VeryLazy",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = function()
		vim.fn["mkdp#util#install"]()
	end,
	keys = {
		{
			"<leader>mp",
			ft = "markdown",
			"<cmd>MarkdownPreviewToggle<cr>",
			desc = "Markdown preview",
		},
	},
	config = function()
		vim.cmd([[do FileType]])
	end,
=======
  "iamcco/markdown-preview.nvim",
  event = "VeryLazy",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  keys = {
    {
      "<leader>mp",
      ft = "markdown",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Markdown preview",
    },
  },
  config = function()
    vim.cmd([[do FileType]])
  end,
>>>>>>> 851b830545db38bb37aa5587b3ef11e8a723fdf7
}
