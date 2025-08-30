-- Ollama Chat Commands and Keybindings
local ollama_manager = require('vinod.ollama_manager')
local ollama_chat = require('vinod.ollama_chat')
local ollama_ui = require('vinod.ollama_ui')
local ollama_session = require('vinod.ollama_session')

-- Initialize ollama manager on load
ollama_manager.setup()

-- User commands
vim.api.nvim_create_user_command('OllamaOpen', function()
    ollama_chat.open_chat()
end, { desc = 'Open Ollama chat with default model' })

vim.api.nvim_create_user_command('OllamaSetDefault', function()
    ollama_chat.set_default_model()
end, { desc = 'Set default Ollama model' })

vim.api.nvim_create_user_command('OllamaSwitch', function()
    ollama_chat.switch_model()
end, { desc = 'Switch Ollama model in current session' })

vim.api.nvim_create_user_command('OllamaToggle', function()
    ollama_chat.toggle_chat()
end, { desc = 'Toggle Ollama chat visibility' })

vim.api.nvim_create_user_command('OllamaClose', function()
    ollama_chat.close_chat()
end, { desc = 'Close Ollama chat session' })

vim.api.nvim_create_user_command('OllamaHorizontal', function()
    ollama_chat.set_horizontal_split()
end, { desc = 'Set Ollama split preference to horizontal' })

vim.api.nvim_create_user_command('OllamaVertical', function()
    ollama_chat.set_vertical_split()
end, { desc = 'Set Ollama split preference to vertical' })

vim.api.nvim_create_user_command('OllamaInfo', function()
    ollama_ui.show_model_info()
end, { desc = 'Show Ollama model information' })

-- Session management commands
vim.api.nvim_create_user_command('OllamaSave', function(opts)
    local name = opts.args and opts.args ~= "" and opts.args or nil
    ollama_session.save_chat(name)
end, { desc = 'Save current Ollama chat', nargs = '?' })

vim.api.nvim_create_user_command('OllamaLoad', function()
    ollama_session.load_chat()
end, { desc = 'Load saved Ollama chat' })

vim.api.nvim_create_user_command('OllamaClear', function()
    ollama_session.clear_all_chats()
end, { desc = 'Clear all saved Ollama chats' })

vim.api.nvim_create_user_command('OllamaChats', function()
    ollama_session.show_chat_info()
end, { desc = 'Show saved chat information' })



-- Keybindings
local opts = { noremap = true, silent = true }

-- Primary operations
vim.keymap.set('n', '<leader>od', function()
    ollama_chat.set_default_model()
end, vim.tbl_extend('force', opts, { desc = 'Set default Ollama model' }))

vim.keymap.set('n', '<leader>oo', function()
    ollama_chat.open_chat()
end, vim.tbl_extend('force', opts, { desc = 'Open Ollama chat' }))

vim.keymap.set('n', '<leader>om', function()
    ollama_chat.switch_model()
end, vim.tbl_extend('force', opts, { desc = 'Switch Ollama model' }))

vim.keymap.set('n', '<leader>ot', function()
    ollama_chat.toggle_chat()
end, vim.tbl_extend('force', opts, { desc = 'Toggle Ollama chat' }))

vim.keymap.set('n', '<leader>oc', function()
    ollama_chat.close_chat()
end, vim.tbl_extend('force', opts, { desc = 'Close Ollama chat' }))

-- Layout control
vim.keymap.set('n', '<leader>oH', function()
    ollama_chat.set_horizontal_split()
end, vim.tbl_extend('force', opts, { desc = 'Set horizontal split' }))

vim.keymap.set('n', '<leader>oV', function()
    ollama_chat.set_vertical_split()
end, vim.tbl_extend('force', opts, { desc = 'Set vertical split' }))

-- Session management keybindings
vim.keymap.set('n', '<leader>ow', function()
    ollama_session.save_chat()
end, vim.tbl_extend('force', opts, { desc = 'Save Ollama chat' }))

vim.keymap.set('n', '<leader>ol', function()
    ollama_session.load_chat()
end, vim.tbl_extend('force', opts, { desc = 'Load Ollama chat' }))

vim.keymap.set('n', '<leader>ox', function()
    ollama_session.clear_all_chats()
end, vim.tbl_extend('force', opts, { desc = 'Clear all saved chats' }))

-- Info command (useful for debugging and status)
vim.keymap.set('n', '<leader>oi', function()
    ollama_ui.show_model_info()
end, vim.tbl_extend('force', opts, { desc = 'Show Ollama info' }))

-- Buffer context commands (API-only approach)
vim.keymap.set('n', '<leader>ob', function()
    ollama_chat.send_buffer_context()
end, vim.tbl_extend('force', opts, { desc = 'Send buffer to Ollama via API' }))

vim.keymap.set('v', '<leader>os', function()
    ollama_chat.send_visual_selection()
end, vim.tbl_extend('force', opts, { desc = 'Send selection to Ollama via API' }))


-- Help command
vim.api.nvim_create_user_command('OllamaHelp', function()
    local keymaps = {
        ["Essential Commands"] = {
            [":OllamaOpen"] = "Open chat with default model",
            [":OllamaSetDefault"] = "Set/change default model",
            [":OllamaSwitch"] = "Switch model in current session",
            [":OllamaToggle"] = "Toggle chat visibility",
            [":OllamaClose"] = "Close chat session",
            [":OllamaInfo"] = "Show model and session information",
        },
        ["Primary Operations"] = {
            ["<leader>od"] = "Set/change default model (persistent)",
            ["<leader>oo"] = "Open chat with default model",
            ["<leader>om"] = "Switch model in existing chat",
            ["<leader>ot"] = "Toggle chat pane visibility",
            ["<leader>oc"] = "Close chat session"
        },
        ["Layout Control"] = {
            ["<leader>oH"] = "Force horizontal split (persistent preference)",
            ["<leader>oV"] = "Force vertical split (persistent preference)"
        },
        ["Session Management"] = {
            ["<leader>ow"] = "Save current chat with user-provided name",
            ["<leader>ol"] = "Load saved chat as new buffer",
            ["<leader>ox"] = "Clear all saved chats (with confirmation)",
            [":OllamaSave [name]"] = "Save current chat with optional name",
            [":OllamaLoad"] = "Load saved chat",
            [":OllamaClear"] = "Clear all saved chats"
        },
        ["Information & Help"] = {
            ["<leader>oi"] = "Show model and session info",
            ["<leader>oh"] = "Show this help window",
            [":OllamaChats"] = "Show saved chat information"
        },
        ["Buffer Context (API-Only)"] = {
            ["<leader>ob"] = "Send current buffer content to Ollama via API",
            ["<leader>os"] = "Send visual selection to Ollama via API (visual mode)"
        },
        ["Model Management"] = {
            ["Validation"] = "Check model availability before starting chat",
            ["Progress Feedback"] = "Status updates with vim.notify()",
            ["Model Switching"] = "Kill current process, start new model gracefully",
            ["Error Recovery"] = "Prompt for new selection if default unavailable"
        },
        ["Daily Workflow"] = {
            ["Start"] = "<leader>oo - Start chat with default model",
            ["Work"] = "Use AI assistance for development tasks",
            ["Hide"] = "<leader>ot - Hide chat when focusing on code",
            ["Show"] = "<leader>ot - Show chat when need assistance again",
            ["Save"] = "<leader>ow session-name - Save important conversations",
            ["Switch"] = "<leader>om - Change model during conversation"
        },
        ["Configuration"] = {
            ["Location"] = "~/.config/nvim/ollama_config.lua",
            ["Format"] = "Lua table with default_model and split_preference",
            ["Storage"] = "~/.local/share/nvim/ollama/chats/ for saved conversations",
            ["Auto-cleanup"] = "Remove chats older than 30 days on startup"
        },
        ["Environment Integration"] = {
            ["Tmux Detection"] = "Uses $TMUX environment variable",
            ["UI Selection"] = "Tmux popup vs terminal fzf based on environment",
            ["Split Behavior"] = "50% splits with persistent preference",
            ["Process Lifecycle"] = "Natural cleanup when sessions close"
        }
    }
    
    -- Create floating window
    local width = 95
    local height = 40
    local buf = vim.api.nvim_create_buf(false, true)
    
    local lines = {}
    table.insert(lines, "🤖 Ollama Chat Integration Help")
    table.insert(lines, string.rep("═", width - 4))
    table.insert(lines, "")
    
    for section, items in pairs(keymaps) do
        table.insert(lines, "▶ " .. section)
        table.insert(lines, string.rep("─", #section + 2))
        table.insert(lines, "")
        
        for key, desc in pairs(items) do
            local line = string.format("  %-35s %s", key, desc)
            if #line > width - 4 then
                -- Wrap long lines
                local key_part = string.format("  %-35s", key)
                table.insert(lines, key_part)
                table.insert(lines, string.format("  %35s %s", "", desc))
            else
                table.insert(lines, line)
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, string.rep("═", width - 4))
    table.insert(lines, "Press 'q' or ESC to close")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "filetype", "ollamahelp")
    
    -- Center the window
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        anchor = "NW",
        style = "minimal",
        border = "rounded",
        title = " 🤖 Ollama Chat Help ",
        title_pos = "center"
    }
    
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    
    -- Set up syntax highlighting
    vim.cmd("syntax match OllamaHelpTitle /^🤖.*$/")
    vim.cmd("syntax match OllamaHelpSection /^▶.*$/")
    vim.cmd("syntax match OllamaHelpSeparator /^[═─].*$/")
    vim.cmd("syntax match OllamaHelpKey /^  [^[:space:]].*$/")
    vim.cmd("syntax match OllamaHelpFooter /^Press.*$/")
    
    vim.cmd("highlight OllamaHelpTitle ctermfg=14 guifg=#00D7D7 cterm=bold gui=bold")
    vim.cmd("highlight OllamaHelpSection ctermfg=11 guifg=#FFD700 cterm=bold gui=bold")
    vim.cmd("highlight OllamaHelpSeparator ctermfg=8 guifg=#666666")
    vim.cmd("highlight OllamaHelpKey ctermfg=10 guifg=#90EE90")
    vim.cmd("highlight OllamaHelpFooter ctermfg=8 guifg=#666666 cterm=italic gui=italic")
    
    -- Set up close keymaps
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set("n", "<ESC>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
end, {
    desc = 'Show Ollama chat help with all commands and keybindings'
})

-- Help keybinding
vim.keymap.set('n', '<leader>oh', function()
    vim.cmd('OllamaHelp')
end, vim.tbl_extend('force', opts, { desc = 'Show Ollama help' }))

