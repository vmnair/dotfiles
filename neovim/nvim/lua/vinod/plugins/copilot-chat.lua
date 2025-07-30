return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "zbirenbaum/copilot.lua" },                -- or github/copilot.vim
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log wrapper
      -- { "nvim-telescope/telescope.nvim" },
      { "ibhagwan/fzf-lua" },
    },

    build = "make tiktoken",
    opts = function()
      return {
        system_prompt = "COPILOT_INSTRUCTIONS", -- System prompt to use (can be specified manually in prompt via /).

        model = "gpt-3.1",                  -- Default model to use, see ':CopilotChatModels' for available models (can be specified manually in prompt via $).
        -- picker = "fzf-lua",

        temperature = 1.1,     -- Result temperature
        remember_as_sticky = true, -- Remember model as sticky prompts when asking questions

        -- default selection
        -- see select.lua for implementation
        selection = require("CopilotChat.select").visual,

        -- default window options
        window = {
          layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace', or a function that returns the layout
          width = 1.5,       -- fractional width of parent, or absolute width in columns when > 1
          height = 1.5,      -- fractional height of parent, or absolute height in rows when > 1
          -- Options below only apply to floating windows
          relative = "editor", -- 'editor', 'win', 'cursor', 'mouse'
          border = "single", -- 'none', single', 'double', 'rounded', 'solid', 'shadow'
          row = nil,         -- row position of the window, default is centered
          col = nil,         -- column position of the window, default is centered
          title = "Copilot Chat", -- title of chat window
          footer = function(config)
            -- return "Model: " .. (config.model or config.options and config.options.model or "gpt-3.1")
            return vim.inspect(config)
          end,   -- footer of chat window
          zindex = 2, -- determines if window is on top or below other floating windows
        },

        show_help = true,             -- Shows help message as virtual lines when waiting for user input
        show_folds = true,            -- Shows folds for sections in chat
        highlight_selection = true,   -- Highlight selection
        highlight_headers = true,     -- Highlight headers in chat, disable if using markdown renderers (like render-markdown.nvim)
        auto_follow_cursor = true,    -- Auto-follow cursor in chat
        auto_insert_mode = false,     -- Automatically enter insert mode when opening window and on new prompt
        insert_at_end = false,        -- Move cursor to end of buffer when inserting text
        clear_chat_on_new_prompt = false, -- Clears chat on every new prompt

        -- Static config starts here (can be configured only via setup function)

        debug = false,                                               -- Enable debug logging (same as 'log_level = 'debug')
        log_level = "info",                                          -- Log level to use, 'trace', 'debug', 'info', 'warn', 'error', 'fatal'
        proxy = nil,                                                 -- [protocol://]host[:port] Use this proxy
        allow_insecure = false,                                      -- Allow insecure server connections

        chat_autocomplete = true,                                    -- Enable chat autocompletion (when disabled, requires manual `mappings.complete` trigger)

        log_path = vim.fn.stdpath("state") .. "/CopilotChat.log",    -- Default path to log file
        history_path = vim.fn.stdpath("data") .. "/copilotchat_history", -- Default path to stored history

        headers = {
          user = "## User ",    -- Header to use for user questions
          assistant = "## Copilot ", -- Header to use for AI answers
          tool = "## Tool ",    -- Header to use for tool calls
        },

        separator = "───", -- Separator to use in chat

        -- default providers
        -- see config/providers.lua for implementation
        providers = require("CopilotChat.config.providers"),

        -- default functions
        -- see config/functions.lua for implementation
        functions = require("CopilotChat.config.functions"),

        -- default prompts
        -- see config/prompts.lua for implementation
        prompts = require("CopilotChat.config.prompts"),

        -- default mappings
        -- see config/mappings.lua for implementation
        mappings = require("CopilotChat.config.mappings"),
      }
    end,
  },
}
