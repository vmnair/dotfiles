-- =====================================================
-- Neovim Commands and Keybindings for Vinod's Todo Manager
-- =====================================================
-- This file defines all user commands and key mappings for the todo system
-- Commands are organized by functionality: adding, listing, managing, and viewing todos
-- Key mappings are set up for todo files to enable spacebar toggling and filtering

local todo_manager = require('vinod.todo_manager')

-- Initialize the todo system when this module loads
-- Creates necessary directories and files if they don't exist
todo_manager.init_todo_files()

-- Parse user input for the TodoAdd command
-- Handles multiple syntaxes:
-- 1. Pipe syntax: "Description | Category: Medicine | Tags: #tag1 | Due: 07-20-2025"
-- 2. Direct hashtag: "Description #tag1 #tag2 | Category: Medicine | Due: 07-20-2025"
-- 3. Mixed syntax: "Description #urgent | Tags: #pharmacy | Category: Medicine"
-- Also handles calendar picker: "Description #tag /cal" or "Description | Category: Medicine /cal"
-- Returns: description, category, tags array, due_date, use_calendar
local function parse_add_todo_args(args)
    local description = ""
    local category = ""
    local tags = {}
    local due_date = ""
    local use_calendar = false
    
    -- Check for /cal suffix
    if args:match("%s*/cal%s*$") then
        use_calendar = true
        args = args:gsub("%s*/cal%s*$", "") -- Remove /cal suffix
    end
    
    -- First, extract hashtags from anywhere in the input and collect them
    local hashtag_pattern = "#(%w+)"
    for tag in args:gmatch(hashtag_pattern) do
        table.insert(tags, tag)
    end
    
    -- Split input by pipe character to separate description from metadata
    local parts = vim.split(args, "|", { trimempty = true })
    
    for i, part in ipairs(parts) do
        part = vim.trim(part)
        
        if i == 1 then
            -- This is the description part - remove hashtags from it
            description = part:gsub("#%w+", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        elseif part:match("^[Cc]ategory:") then
            category = part:match("^[Cc]ategory:%s*(.+)$")
        elseif part:match("^[Tt]ags:") then
            -- Also support the old Tags: syntax and merge with hashtags
            local tag_str = part:match("^[Tt]ags:%s*(.+)$")
            for tag in tag_str:gmatch("#?(%w+)") do
                -- Avoid duplicates
                local found = false
                for _, existing_tag in ipairs(tags) do
                    if existing_tag == tag then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(tags, tag)
                end
            end
        elseif part:match("^[Dd]ue:") then
            due_date = part:match("^[Dd]ue:%s*(.+)$")
        end
    end
    
    return description, category, tags, due_date, use_calendar
end

-- ================
-- ADDING COMMANDS
-- ================

-- Main command for adding todos with full metadata support
-- Usage examples:
--   :TodoAdd Buy medicine #urgent #pharmacy | Category: Medicine | Due: 07-20-2025
--   :TodoAdd Buy medicine #urgent | Category: Medicine /cal
--   :TodoAdd Meeting with doctor #important /cal
-- Calendar picker: Use /cal suffix to select date with calendar
-- All fields except description are optional
-- Category defaults to "Personal" if not specified
vim.api.nvim_create_user_command('TodoAdd', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoAdd <description> [#tag1 #tag2] [| Category: <category>] [| Due: mm-dd-yyyy]")
        print("Examples: TodoAdd Buy medicine #urgent | Category: Medicine")
        print("         TodoAdd Meeting prep #work /cal")
        print("Calendar: Add /cal suffix to use date picker")
        print("Note: Category defaults to 'Personal' if not specified")
        return
    end
    
    local description, category, tags, due_date, use_calendar = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    -- Handle calendar picker - use today's date if no date selected
    if use_calendar then
        todo_manager.get_date_input(function(picked_date)
            -- Use picked date or fallback to today's date
            if picked_date then
                due_date = picked_date
            else
                due_date = os.date("%m-%d-%Y")  -- Today's date in mm-dd-yyyy format
                print("No date selected, using today's date: " .. due_date)
            end
            
            local success = todo_manager.add_todo(description, category, tags, due_date)
            if success then
                local cat_display = category and category ~= "" and category or "Personal"
                local due_display = " [Due: " .. due_date .. "]"
                print("✓ Todo added: " .. description .. " (" .. cat_display .. ")" .. due_display)
            else
                print("✗ Failed to add todo")
            end
        end)
    else
        local success = todo_manager.add_todo(description, category, tags, due_date)
        if success then
            local cat_display = category and category ~= "" and category or "Personal"
            local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
            print("✓ Todo added: " .. description .. " (" .. cat_display .. ")" .. due_display)
        else
            print("✗ Failed to add todo")
        end
    end
end, {
    nargs = '*',
    desc = 'Add a new todo with hashtag syntax support (use /cal for calendar picker)'
})

-- Quick command for adding Personal category todos (most common use case)
-- Usage examples:
--   :Todo Buy groceries #urgent | Due: 07-25-2025
--   :Todo Buy groceries #urgent /cal
--   :Todo Meeting preparation #work
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "Personal", supports hashtag syntax and due dates
vim.api.nvim_create_user_command('Todo', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :Todo <description> [#tag1 #tag2] [| Due: mm-dd-yyyy]")
        print("Examples: Todo Buy groceries #urgent")
        print("         Todo Call dentist #health /cal")
        print("Calendar: Add /cal suffix to use date picker")
        print("Creates a Personal category todo")
        return
    end
    
    local description, _, tags, due_date, use_calendar = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    -- Handle calendar picker - use today's date if no date selected
    if use_calendar then
        todo_manager.get_date_input(function(picked_date)
            -- Use picked date or fallback to today's date
            if picked_date then
                due_date = picked_date
            else
                due_date = os.date("%m-%d-%Y")  -- Today's date in mm-dd-yyyy format
                print("No date selected, using today's date: " .. due_date)
            end
            
            local success = todo_manager.add_todo(description, "Personal", tags, due_date)
            if success then
                local due_display = " [Due: " .. due_date .. "]"
                print("✓ Personal todo added: " .. description .. due_display)
            else
                print("✗ Failed to add todo")
            end
        end)
    else
        local success = todo_manager.add_todo(description, "Personal", tags, due_date)
        if success then
            local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
            print("✓ Personal todo added: " .. description .. due_display)
        else
            print("✗ Failed to add todo")
        end
    end
end, {
    nargs = '*',
    desc = 'Quick add a Personal category todo with hashtag syntax (use /cal for calendar)'
})

-- Quick command for adding Medicine category todos
-- Usage examples:
--   :TodoMed Take medication #urgent | Due: 07-25-2025
--   :TodoMed Take medication #urgent /cal
--   :TodoMed Doctor appointment #followup
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "Medicine", supports hashtag syntax and due dates
vim.api.nvim_create_user_command('TodoMed', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoMed <description> [#tag1 #tag2] [| Due: mm-dd-yyyy]")
        print("Examples: TodoMed Take medication #morning")
        print("         TodoMed Doctor appointment #followup /cal")
        print("Calendar: Add /cal suffix to use date picker")
        return
    end
    
    local description, _, tags, due_date, use_calendar = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    -- Handle calendar picker - use today's date if no date selected
    if use_calendar then
        todo_manager.get_date_input(function(picked_date)
            -- Use picked date or fallback to today's date
            if picked_date then
                due_date = picked_date
            else
                due_date = os.date("%m-%d-%Y")  -- Today's date in mm-dd-yyyy format
                print("No date selected, using today's date: " .. due_date)
            end
            
            local success = todo_manager.add_todo(description, "Medicine", tags, due_date)
            if success then
                local due_display = " [Due: " .. due_date .. "]"
                print("✓ Medicine todo added: " .. description .. due_display)
            else
                print("✗ Failed to add todo")
            end
        end)
    else
        local success = todo_manager.add_todo(description, "Medicine", tags, due_date)
        if success then
            local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
            print("✓ Medicine todo added: " .. description .. due_display)
        else
            print("✗ Failed to add todo")
        end
    end
end, {
    nargs = '*',
    desc = 'Quick add a Medicine category todo with hashtag syntax (use /cal for calendar)'
})

-- Quick command for adding OMS category todos
-- Usage examples:
--   :TodoOMS Review patient charts #urgent | Due: 07-25-2025
--   :TodoOMS Review patient charts #urgent /cal
--   :TodoOMS Update documentation #priority
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "OMS", supports hashtag syntax and due dates
vim.api.nvim_create_user_command('TodoOMS', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoOMS <description> [#tag1 #tag2] [| Due: mm-dd-yyyy]")
        print("Examples: TodoOMS Review charts #urgent")
        print("         TodoOMS Update system #maintenance /cal")
        print("Calendar: Add /cal suffix to use date picker")
        return
    end
    
    local description, _, tags, due_date, use_calendar = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    -- Handle calendar picker - use today's date if no date selected
    if use_calendar then
        todo_manager.get_date_input(function(picked_date)
            -- Use picked date or fallback to today's date
            if picked_date then
                due_date = picked_date
            else
                due_date = os.date("%m-%d-%Y")  -- Today's date in mm-dd-yyyy format
                print("No date selected, using today's date: " .. due_date)
            end
            
            local success = todo_manager.add_todo(description, "OMS", tags, due_date)
            if success then
                local due_display = " [Due: " .. due_date .. "]"
                print("✓ OMS todo added: " .. description .. due_display)
            else
                print("✗ Failed to add todo")
            end
        end)
    else
        local success = todo_manager.add_todo(description, "OMS", tags, due_date)
        if success then
            local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
            print("✓ OMS todo added: " .. description .. due_display)
        else
            print("✗ Failed to add todo")
        end
    end
end, {
    nargs = '*',
    desc = 'Quick add an OMS category todo with hashtag syntax (use /cal for calendar)'
})

-- ================
-- LISTING COMMANDS
-- ================

-- List all active todos with optional category filtering
-- Usage: :TodoList [category]
-- Shows numbered list suitable for use with TodoComplete/TodoDelete
vim.api.nvim_create_user_command('TodoList', function(opts)
    local category = opts.args ~= "" and opts.args or nil
    todo_manager.list_active_todos(category)
end, {
    nargs = '?',
    desc = 'List active todos, optionally filtered by category'
})

-- List all completed todos with optional category filtering
-- Usage: :TodoCompleted [category]
-- Shows historical view of completed tasks
vim.api.nvim_create_user_command('TodoCompleted', function(opts)
    local category = opts.args ~= "" and opts.args or nil
    todo_manager.list_completed_todos(category)
end, {
    nargs = '?',
    desc = 'List completed todos, optionally filtered by category'
})

-- Show comprehensive category view (both active and completed todos)
-- Usage: :TodoCategory <Medicine|OMS|Personal>
-- Displays both active and completed todos for the category with statistics
vim.api.nvim_create_user_command('TodoCategory', function(opts)
    local category = opts.args
    if category == "" then
        print("Usage: :TodoCategory <Medicine|OMS|Personal>")
        return
    end
    todo_manager.list_todos_by_category(category)
end, {
    nargs = 1,
    desc = 'Show both active and completed todos for a specific category'
})

-- List all todos that have due dates in interactive buffer
-- Usage: :TodoDue
vim.api.nvim_create_user_command('TodoDue', function()
    -- First open the active todos file, then apply the filter
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
    vim.cmd('edit ' .. file_path)
    -- Apply the due dates filter which creates an interactive buffer
    todo_manager.filter_todos_by_due_dates()
end, {
    desc = 'Open interactive buffer showing todos with due dates'
})

-- List all past due todos in interactive buffer
-- Usage: :TodoPastDue
vim.api.nvim_create_user_command('TodoPastDue', function()
    -- First open the active todos file, then apply the filter
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
    vim.cmd('edit ' .. file_path)
    -- Apply the past due filter which creates an interactive buffer
    todo_manager.filter_todos_by_past_due()
end, {
    desc = 'Open interactive buffer showing past due todos'
})

-- List all todos due today in interactive buffer
-- Usage: :TodoToday
vim.api.nvim_create_user_command('TodoToday', function()
    -- First open the active todos file, then apply the filter
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
    vim.cmd('edit ' .. file_path)
    -- Apply the today filter which creates an interactive buffer
    todo_manager.filter_todos_by_today()
end, {
    desc = 'Open interactive buffer showing todos due today'
})

-- List todos due today and past due in interactive buffer
-- Usage: :TodoTodayAndPastDue
vim.api.nvim_create_user_command('TodoTodayAndPastDue', function()
    -- First open the active todos file, then apply the filter
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
    vim.cmd('edit ' .. file_path)
    -- Apply the today and past due filter which creates an interactive buffer
    todo_manager.filter_todos_by_today_and_past_due()
end, {
    desc = 'Open interactive buffer showing todos due today or past due'
})


-- ===================
-- MANAGEMENT COMMANDS
-- ===================

-- Complete a todo by its index number
-- Usage: :TodoComplete 1
-- Moves the todo from active to completed file with completion date
vim.api.nvim_create_user_command('TodoComplete', function(opts)
    local index = tonumber(opts.args)
    if not index then
        print("Usage: :TodoComplete <index>")
        print("Use :TodoList to see todo indices")
        return
    end
    
    local success = todo_manager.complete_todo(index)
    if success then
        print("✓ Todo completed!")
    else
        print("✗ Failed to complete todo. Check the index with :TodoList")
    end
end, {
    nargs = 1,
    desc = 'Complete a todo by its index number'
})

-- Permanently delete a todo by its index number
-- Usage: :TodoDelete 1
-- Removes the todo completely (does not move to completed)
vim.api.nvim_create_user_command('TodoDelete', function(opts)
    local index = tonumber(opts.args)
    if not index then
        print("Usage: :TodoDelete <index>")
        print("Use :TodoList to see todo indices")
        return
    end
    
    local success = todo_manager.delete_todo(index)
    if success then
        print("✓ Todo deleted!")
    else
        print("✗ Failed to delete todo. Check the index with :TodoList")
    end
end, {
    nargs = 1,
    desc = 'Delete a todo by its index number'
})

-- =====================
-- FILE ACCESS COMMANDS
-- =====================

-- Open the active todos file for editing
-- Opens active-todos.md in current window
vim.api.nvim_create_user_command('TodoOpen', function()
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
    vim.cmd('edit ' .. file_path)
end, {
    desc = 'Open the active todos file for editing'
})

-- Open the completed todos file for viewing
-- Opens completed-todos.md in current window
vim.api.nvim_create_user_command('TodoOpenCompleted', function()
    local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.completed_file
    vim.cmd('edit ' .. file_path)
end, {
    desc = 'Open the completed todos file for viewing'
})

-- ====================
-- INFORMATION COMMANDS
-- ====================

-- Show comprehensive todo statistics
-- Displays counts by category for both active and completed todos
vim.api.nvim_create_user_command('TodoStats', function()
    local active_todos = todo_manager.get_active_todos()
    local completed_todos = todo_manager.get_completed_todos()
    
    -- Count by category
    local active_by_category = {}
    local completed_by_category = {}
    
    for _, todo in ipairs(active_todos) do
        local cat = todo.category ~= "" and todo.category or "Uncategorized"
        active_by_category[cat] = (active_by_category[cat] or 0) + 1
    end
    
    for _, todo in ipairs(completed_todos) do
        local cat = todo.category ~= "" and todo.category or "Uncategorized"
        completed_by_category[cat] = (completed_by_category[cat] or 0) + 1
    end
    
    print("\nTodo Statistics:")
    print("================")
    print("Active todos: " .. #active_todos)
    print("Completed todos: " .. #completed_todos)
    print("Total todos: " .. (#active_todos + #completed_todos))
    
    print("\nActive todos by category:")
    for category, count in pairs(active_by_category) do
        print("  " .. category .. ": " .. count)
    end
    
    print("\nCompleted todos by category:")
    for category, count in pairs(completed_by_category) do
        print("  " .. category .. ": " .. count)
    end
    print("")
end, {
    desc = 'Show todo statistics'
})

-- ===================
-- MAINTENANCE COMMANDS
-- ===================

-- Clean up any completed todos that may be in active file
-- Moves completed todos from active file to completed file
vim.api.nvim_create_user_command('TodoCleanup', function()
    todo_manager.cleanup_completed_todos()
    print("✓ Cleaned up completed todos!")
end, {
    desc = 'Move any completed todos from active file to completed file'
})


-- Toggle completion status of todo on current line
-- Usage: :TodoToggle (also mapped to spacebar in todo files)
-- Handles moving todos between files when appropriate
vim.api.nvim_create_user_command('TodoToggle', function()
    todo_manager.toggle_todo_on_line()
end, {
    desc = 'Toggle completion status of todo on current line'
})

-- Create zk note from todo on current line
-- Usage: :TodoNote
-- Creates a note using the todo description as title and prompts for directory
vim.api.nvim_create_user_command('TodoNote', function()
    todo_manager.create_note_from_todo()
end, {
    desc = 'Create zk note from todo on current line'
})

-- Display all todo manager keymaps in a floating window
-- Usage: :TodoHelp
vim.api.nvim_create_user_command('TodoHelp', function()
    local keymaps = {
        ["Commands"] = {
            [":TodoAdd <desc> [#tags] [| Category: <cat>] [| Due: mm-dd-yyyy]"] = "Add new todo with full metadata",
            [":Todo <desc> [#tags] [| Due: mm-dd-yyyy]"] = "Quick add Personal category todo",
            [":TodoMed <desc> [#tags] [| Due: mm-dd-yyyy]"] = "Quick add Medicine category todo", 
            [":TodoOMS <desc> [#tags] [| Due: mm-dd-yyyy]"] = "Quick add OMS category todo",
            [":TodoList [category]"] = "List active todos",
            [":TodoCompleted [category]"] = "List completed todos",
            [":TodoCategory <category>"] = "Show category overview",
            [":TodoDue"] = "Show todos with due dates",
            [":TodoPastDue"] = "Show past due todos", 
            [":TodoToday"] = "Show todos due today",
            [":TodoOpen"] = "Open active todos file",
            [":TodoNote"] = "Create zk note from current todo",
            [":TodoToggle"] = "Toggle todo completion",
            [":TodoStats"] = "Show todo statistics",
            [":TodoHelp"] = "Show this help window"
        },
        ["Keybindings (in todo files)"] = {
            ["tt"] = "Toggle todo completion",
            ["<leader>cn"] = "Create zk note from todo",
            ["<leader>cd"] = "Update due date with calendar",
            ["<leader>vm"] = "Filter Medicine todos",
            ["<leader>vo"] = "Filter OMS todos", 
            ["<leader>vp"] = "Filter Personal todos",
            ["<leader>va"] = "Show all todos",
            ["<leader>vd"] = "Filter todos with due dates",
            ["<leader>vt"] = "Filter todos due today",
            ["<leader>vx"] = "Filter urgent todos (today + past due)",
            ["<leader>vq"] = "Close filter window"
        },
        ["Calendar Picker"] = {
            ["h/l"] = "Previous/Next month",
            ["j/k"] = "Previous/Next day", 
            ["H/L"] = "Previous/Next year",
            ["Enter"] = "Select date",
            ["q/ESC"] = "Cancel"
        }
    }
    
    -- Create floating window
    local width = 80
    local height = 25
    local buf = vim.api.nvim_create_buf(false, true)
    
    local lines = {}
    table.insert(lines, "🔹 Todo Manager Help")
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
    vim.api.nvim_buf_set_option(buf, "filetype", "todohelp")
    
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
        title = " 📚 Todo Manager Help ",
        title_pos = "center"
    }
    
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    
    -- Set up syntax highlighting
    vim.cmd("syntax match TodoHelpTitle /^🔹.*$/")
    vim.cmd("syntax match TodoHelpSection /^▶.*$/")
    vim.cmd("syntax match TodoHelpSeparator /^[═─].*$/")
    vim.cmd("syntax match TodoHelpKey /^  [^[:space:]].*$/")
    vim.cmd("syntax match TodoHelpFooter /^Press.*$/")
    
    vim.cmd("highlight TodoHelpTitle ctermfg=14 guifg=#00D7D7 cterm=bold gui=bold")
    vim.cmd("highlight TodoHelpSection ctermfg=11 guifg=#FFD700 cterm=bold gui=bold")
    vim.cmd("highlight TodoHelpSeparator ctermfg=8 guifg=#666666")
    vim.cmd("highlight TodoHelpKey ctermfg=10 guifg=#90EE90")
    vim.cmd("highlight TodoHelpFooter ctermfg=8 guifg=#666666 cterm=italic gui=italic")
    
    -- Set up close keymaps
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set("n", "<ESC>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
end, {
    desc = 'Show todo manager help with all commands and keybindings'
})

-- ========================
-- AUTO-COMMANDS AND KEYBINDINGS
-- ========================

-- Set up automatic behavior when entering todo files
-- Enables spacebar toggling and sets up keybindings
-- Applies to any .md file in the /todo/ directory
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
    pattern = {"*/todo/*.md"},
    callback = function()
        -- Map tt to toggle todo completion (primary interaction)
        -- Works on any line containing a todo item (normal mode only)
        vim.keymap.set('n', 'tt', function()
            todo_manager.toggle_todo_on_line()
        end, { 
            buffer = true, 
            desc = 'Toggle todo completion',
            silent = true 
        })
        
        -- ========================
        -- FILTERING KEYBINDINGS (CUSTOM BUFFER)
        -- ========================
        -- Custom buffer filtering system - clean display without quickfix clutter
        -- Opens a scratch buffer showing filtered todos with navigation
        
        -- Medicine category filter
        vim.keymap.set('n', '<leader>vm', function()
            todo_manager.filter_todos_by_category("Medicine")
        end, { 
            buffer = true, 
            desc = 'Filter Medicine todos',
            silent = true 
        })
        
        -- Personal category filter
        vim.keymap.set('n', '<leader>vp', function()
            todo_manager.filter_todos_by_category("Personal")
        end, { 
            buffer = true, 
            desc = 'Filter Personal todos',
            silent = true 
        })
        
        -- OMS category filter
        vim.keymap.set('n', '<leader>vo', function()
            todo_manager.filter_todos_by_category("OMS")
        end, { 
            buffer = true, 
            desc = 'Filter OMS todos',
            silent = true 
        })
        
        -- Show all todos (no filtering)
        vim.keymap.set('n', '<leader>va', function()
            todo_manager.show_all_todos()
        end, { 
            buffer = true, 
            desc = 'Show all todos',
            silent = true 
        })
        
        -- Filter by due dates
        vim.keymap.set('n', '<leader>vd', function()
            todo_manager.filter_todos_by_due_dates()
        end, { 
            buffer = true, 
            desc = 'Filter todos with due dates',
            silent = true 
        })
        
        -- Filter by today's due date
        vim.keymap.set('n', '<leader>vt', function()
            todo_manager.filter_todos_by_today()
        end, { 
            buffer = true, 
            desc = 'Filter todos due today',
            silent = true 
        })
        
        -- Filter by today and past due
        vim.keymap.set('n', '<leader>vx', function()
            todo_manager.filter_todos_by_today_and_past_due()
        end, { 
            buffer = true, 
            desc = 'Filter todos due today or past due',
            silent = true 
        })
        
        -- Update due date on current line using calendar picker
        vim.keymap.set('n', '<leader>cd', function()
            todo_manager.update_todo_date_on_line()
        end, { 
            buffer = true, 
            desc = 'Update due date with calendar picker',
            silent = true 
        })
        
        -- Create zk note from todo on current line
        vim.keymap.set('n', '<leader>cn', function()
            todo_manager.create_note_from_todo()
        end, { 
            buffer = true, 
            desc = 'Create zk note from todo',
            silent = true 
        })
        
        -- Close filter window
        vim.keymap.set('n', '<leader>vq', function()
            vim.cmd('close')
            print("✓ Filter window closed")
        end, { 
            buffer = true, 
            desc = 'Close filter window',
            silent = true 
        })
        
        
        -- Setup syntax highlighting for better visual appearance
        todo_manager.setup_todo_syntax()
        
        -- Also apply due date highlighting automatically
        todo_manager.highlight_due_dates_with_colors()
    end
})

-- Add autocmds for real-time syntax highlighting updates
-- Reapply highlighting when buffer content changes
vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    pattern = {"*/todo/*.md"},
    callback = function()
        -- Debounce: only refresh highlighting after a short delay
        vim.defer_fn(function()
            todo_manager.highlight_due_dates_with_colors()
        end, 200)
    end
})

-- Also refresh highlighting when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = {"*/todo/*.md"},
    callback = function()
        todo_manager.highlight_due_dates_with_colors()
    end
})


-- =============================
-- OPTIONAL GLOBAL KEYBINDINGS
-- =============================
-- These are optional keybindings for quick access to todo commands
-- Currently commented out - uncomment the ones you want to use
-- You can customize the leader key combinations as needed

-- vim.keymap.set('n', '<leader>ta', ':TodoAdd ', { desc = 'Add new todo' })
-- vim.keymap.set('n', '<leader>tl', ':TodoList<CR>', { desc = 'List active todos' })
-- vim.keymap.set('n', '<leader>tc', ':TodoCompleted<CR>', { desc = 'List completed todos' })
-- vim.keymap.set('n', '<leader>to', ':TodoOpen<CR>', { desc = 'Open active todos file' })
-- vim.keymap.set('n', '<leader>ts', ':TodoStats<CR>', { desc = 'Show todo statistics' })


-- ===============================
-- CATEGORY MANAGEMENT COMMANDS
-- ===============================

-- Add a new category with custom icon
-- Usage: :TodoAddCategory Work 💼
vim.api.nvim_create_user_command('TodoAddCategory', function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args < 2 then
        print("Usage: :TodoAddCategory <category_name> <icon>")
        print("Example: :TodoAddCategory Work 💼")
        return
    end
    
    local category_name = args[1]
    local icon = args[2]
    
    local success = todo_manager.add_new_category(category_name, icon)
    if not success then
        print("Failed to add category")
    end
end, {
    nargs = '*',
    desc = 'Add a new category with custom icon'
})

-- List all available categories with their icons
-- Usage: :TodoCategories
vim.api.nvim_create_user_command('TodoCategories', function()
    todo_manager.list_categories()
end, {
    desc = 'List all available categories with their icons'
})

-- Update icon for an existing category
-- Usage: :TodoUpdateIcon Medicine 💉
vim.api.nvim_create_user_command('TodoUpdateIcon', function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args < 2 then
        print("Usage: :TodoUpdateIcon <category_name> <new_icon>")
        print("Example: :TodoUpdateIcon Medicine 💉")
        todo_manager.list_categories()
        return
    end
    
    local category_name = args[1]
    local new_icon = args[2]
    
    local success = todo_manager.update_category_icon(category_name, new_icon)
    if not success then
        print("Failed to update category icon")
    end
end, {
    nargs = '*',
    complete = function()
        return todo_manager.config.categories
    end,
    desc = 'Update icon for an existing category'
})




-- Confirm successful loading of the todo system
print("✓ Vinod's Todo Manager loaded successfully!")