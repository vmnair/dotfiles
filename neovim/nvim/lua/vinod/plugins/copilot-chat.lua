return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },

    build = "make tiktoken",
    opts = {
      debug = true, -- Enable debugging
      question_header = "## Vinod ",
      auto_follow_cursor = true,
      highlight_selection = true,
    },
    cmd = { "CopilotChat" }, -- Lazy load
    -- config = function()
    --   local function start_copilotchat_in_insert_mode()
    --     vim.cmd("CopilotChat")
    --     vim.cmd("startinsert") -- Start insert mode
    --   end
    -- end,

    vim.api.nvim_set_keymap("n", "<leader>cp", "<Cmd>CopilotChat<CR>", { noremap = true, silent = true }),
  },
}
