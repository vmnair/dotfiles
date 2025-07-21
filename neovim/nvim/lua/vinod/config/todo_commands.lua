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
-- Handles the full syntax: "Description | Category: Medicine | Tags: #tag1 | Due: 07-20-2025"
-- Splits input by pipe character and extracts each metadata field
-- Returns: description, category, tags array, due_date
local function parse_add_todo_args(args)
    local description = ""
    local category = ""
    local tags = {}
    local due_date = ""
    
    -- Split input by pipe character to separate description from metadata
    -- Each part will be processed to extract specific field types
    local parts = vim.split(args, "|", { trimempty = true })
    
    for i, part in ipairs(parts) do
        part = vim.trim(part)
        
        if i == 1 then
            description = part
        elseif part:match("^[Cc]ategory:") then
            category = part:match("^[Cc]ategory:%s*(.+)$")
        elseif part:match("^[Tt]ags:") then
            local tag_str = part:match("^[Tt]ags:%s*(.+)$")
            for tag in tag_str:gmatch("#?(%w+)") do
                table.insert(tags, tag)
            end
        elseif part:match("^[Dd]ue:") then
            due_date = part:match("^[Dd]ue:%s*(.+)$")
        end
    end
    
    return description, category, tags, due_date
end

-- ================
-- ADDING COMMANDS
-- ================

-- Main command for adding todos with full metadata support
-- Usage: :TodoAdd Buy medicine | Category: Medicine | Tags: #urgent #pharmacy | Due: 07-20-2025
-- All fields except description are optional
-- Category defaults to "Personal" if not specified
vim.api.nvim_create_user_command('TodoAdd', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoAdd <description> [| Category: <category>] [| Tags: #tag1 #tag2] [| Due: mm-dd-yyyy]")
        print("Note: Category defaults to 'Personal' if not specified")
        return
    end
    
    local description, category, tags, due_date = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    local success = todo_manager.add_todo(description, category, tags, due_date)
    if success then
        local cat_display = category and category ~= "" and category or "Personal"
        print("✓ Todo added: " .. description .. " (" .. cat_display .. ")")
    else
        print("✗ Failed to add todo")
    end
end, {
    nargs = '*',
    desc = 'Add a new todo with optional category, tags, and due date (defaults to Personal category)'
})

-- Quick command for adding Personal category todos (most common use case)
-- Usage: :Todo Buy groceries | Due: 07-25-2025 | Tags: #urgent
-- Automatically sets category to "Personal", supports due dates and tags
vim.api.nvim_create_user_command('Todo', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :Todo <description> [| Due: mm-dd-yyyy] [| Tags: #tag1 #tag2]")
        print("Creates a Personal category todo")
        return
    end
    
    local description, _, tags, due_date = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    local success = todo_manager.add_todo(description, "Personal", tags, due_date)
    if success then
        print("✓ Personal todo added: " .. description)
    else
        print("✗ Failed to add todo")
    end
end, {
    nargs = '*',
    desc = 'Quick add a Personal category todo with optional due date and tags'
})

-- Quick command for adding Medicine category todos
-- Usage: :TodoMed Take medication | Due: 07-25-2025 | Tags: #urgent
-- Automatically sets category to "Medicine", supports due dates and tags
vim.api.nvim_create_user_command('TodoMed', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoMed <description> [| Due: mm-dd-yyyy] [| Tags: #tag1 #tag2]")
        return
    end
    
    local description, _, tags, due_date = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    local success = todo_manager.add_todo(description, "Medicine", tags, due_date)
    if success then
        print("✓ Medicine todo added: " .. description)
    else
        print("✗ Failed to add todo")
    end
end, {
    nargs = '*',
    desc = 'Quick add a Medicine category todo with optional due date and tags'
})

-- Quick command for adding OMS category todos
-- Usage: :TodoOMS Review patient charts | Due: 07-25-2025 | Tags: #urgent
-- Automatically sets category to "OMS", supports due dates and tags
vim.api.nvim_create_user_command('TodoOMS', function(opts)
    local args = opts.args
    if args == "" then
        print("Usage: :TodoOMS <description> [| Due: mm-dd-yyyy] [| Tags: #tag1 #tag2]")
        return
    end
    
    local description, _, tags, due_date = parse_add_todo_args(args)
    
    if description == "" then
        print("Error: Description is required")
        return
    end
    
    local success = todo_manager.add_todo(description, "OMS", tags, due_date)
    if success then
        print("✓ OMS todo added: " .. description)
    else
        print("✗ Failed to add todo")
    end
end, {
    nargs = '*',
    desc = 'Quick add an OMS category todo with optional due date and tags'
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

-- List all todos that have due dates
-- Usage: :TodoDue
vim.api.nvim_create_user_command('TodoDue', function()
    todo_manager.list_due_todos()
end, {
    desc = 'List all active todos with due dates'
})

-- List all past due todos
-- Usage: :TodoPastDue
vim.api.nvim_create_user_command('TodoPastDue', function()
    todo_manager.list_past_due_todos()
end, {
    desc = 'List all active todos that are past due'
})

-- ======================
-- CATEGORY VIEW COMMANDS
-- ======================

-- Quick command to view all Medicine todos (active and completed)
vim.api.nvim_create_user_command('TodoMedicineView', function()
    todo_manager.list_todos_by_category("Medicine")
end, {
    desc = 'Show all Medicine category todos (active and completed)'
})

-- Quick command to view all Personal todos (active and completed)
vim.api.nvim_create_user_command('TodoPersonalView', function()
    todo_manager.list_todos_by_category("Personal")
end, {
    desc = 'Show all Personal category todos (active and completed)'
})

-- Quick command to view all OMS todos (active and completed)
vim.api.nvim_create_user_command('TodoOMSView', function()
    todo_manager.list_todos_by_category("OMS")
end, {
    desc = 'Show all OMS category todos (active and completed)'
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

-- Emergency command to force clear all filter state and reload file
-- Usage: :TodoForceReload
-- Clears any stuck filter state and reloads the file from disk
vim.api.nvim_create_user_command('TodoForceReload', function()
    vim.b.todo_filter = nil
    vim.b.todo_original_content = nil
    vim.cmd('e!')  -- Force reload the file from disk
    print("✓ Forced reload of todo file")
end, {
    desc = 'Force reload todo file and clear all filters'
})

-- Toggle completion status of todo on current line
-- Usage: :TodoToggle (also mapped to spacebar in todo files)
-- Handles moving todos between files when appropriate
vim.api.nvim_create_user_command('TodoToggle', function()
    todo_manager.toggle_todo_on_line()
end, {
    desc = 'Toggle completion status of todo on current line'
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
        -- Map spacebar to toggle todo completion (primary interaction)
        -- Works on any line containing a todo item
        vim.keymap.set('n', '<Space>', function()
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
        
        -- Close filter window
        vim.keymap.set('n', '<leader>vq', function()
            vim.cmd('close')
            print("✓ Filter window closed")
        end, { 
            buffer = true, 
            desc = 'Close filter window',
            silent = true 
        })
        
        -- ========================
        -- EMERGENCY KEYBINDINGS
        -- ========================
        
        -- Emergency: clear all state and reload file
        -- Use this if anything gets stuck (legacy from old filtering system)
        vim.keymap.set('n', '<leader>vr', function()
            -- Close any filter windows
            vim.cmd('close')
            -- Clear old filter state (from disabled system)
            vim.b.todo_filter = nil
            vim.b.todo_original_content = nil
            vim.b.todo_statusline = nil
            vim.g.todo_last_filter = nil
            vim.fn.clearmatches()
            vim.wo.conceallevel = 0
            vim.wo.foldlevel = 99
            vim.cmd('normal! zR')
            vim.cmd('normal! zE')
            vim.cmd('e!')
            print("✓ All state cleared and file reloaded")
        end, { 
            buffer = true, 
            desc = 'Emergency: clear all state and reload',
            silent = true 
        })
        
        -- Emergency: force close and reopen file
        -- Last resort if file gets corrupted or stuck
        vim.keymap.set('n', '<leader>vx', function()
            vim.cmd('close') -- Close filter window first
            vim.cmd('q!')
            vim.cmd('TodoOpen')
            print("✓ Force reopened todo file")
        end, { 
            buffer = true, 
            desc = 'Emergency: force reopen file',
            silent = true 
        })
        
        -- Restore any existing filter state (currently minimal)
        -- Part of the disabled filtering system
        todo_manager.restore_filter_on_open()
        
        -- Setup syntax highlighting for better visual appearance
        todo_manager.setup_todo_syntax()
        
        -- Also apply due date highlighting automatically
        todo_manager.highlight_due_dates_with_colors()
    end
})

-- Save filter state when leaving todo files
-- Part of the disabled filtering system - preserves last filter choice
vim.api.nvim_create_autocmd({"BufLeave", "VimLeave"}, {
    pattern = {"*/todo/*.md"},
    callback = function()
        -- Save current filter state to a global variable for this session
        local filter = vim.b.todo_filter
        if filter then
            vim.g.todo_last_filter = filter.category
        else
            vim.g.todo_last_filter = nil
        end
    end
})

-- Restore filter state when entering todo files (DISABLED)
-- This autocmd would automatically restore the last used filter
-- Currently disabled due to filtering issues
-- vim.api.nvim_create_autocmd({"BufEnter"}, {
--     pattern = {"*/todo/*.md"},
--     callback = function()
--         -- Restore filter from global variable if it exists
--         vim.defer_fn(function()
--             if vim.g.todo_last_filter and vim.g.todo_last_filter ~= "All" then
--                 todo_manager.filter_todos_by_category_in_buffer(vim.g.todo_last_filter)
--             end
--         end, 200)
--     end
-- })

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
-- FILTERING COMMANDS
-- ===============================

-- Command to filter todos by category
vim.api.nvim_create_user_command('TodoFilter', function(opts)
    local category = opts.args
    if category == "" then
        print("Usage: :TodoFilter <Medicine|OMS|Personal>")
        return
    end
    todo_manager.filter_todos_by_category(category)
end, {
    nargs = 1,
    complete = function()
        return {"Medicine", "OMS", "Personal"}
    end,
    desc = 'Filter todos by category in custom window'
})

-- Command to show all todos
vim.api.nvim_create_user_command('TodoFilterAll', function()
    todo_manager.show_all_todos()
end, {
    desc = 'Show all todos in custom window'
})

-- Command to filter todos by due dates
vim.api.nvim_create_user_command('TodoFilterDue', function()
    todo_manager.filter_todos_by_due_dates()
end, {
    desc = 'Filter todos with due dates in custom window'
})

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

-- Migrate all existing todos to new clean format
-- Usage: :TodoMigrate
vim.api.nvim_create_user_command('TodoMigrate', function()
    todo_manager.migrate_todos_to_new_format()
end, {
    desc = 'Convert all existing todos from old pipe format to new clean format with icons'
})

-- Clean HTML elements and migrate to clean format
-- Usage: :TodoCleanHTML
vim.api.nvim_create_user_command('TodoCleanHTML', function()
    todo_manager.cleanup_html_and_migrate()
end, {
    desc = 'Remove HTML span elements and convert to clean format with syntax highlighting'
})

-- Refresh syntax highlighting for current todo file
-- Usage: :TodoSyntax
vim.api.nvim_create_user_command('TodoSyntax', function()
    todo_manager.setup_todo_syntax()
    print("✓ Todo syntax highlighting refreshed")
end, {
    desc = 'Refresh syntax highlighting for todo files'
})

-- Manually highlight past due dates
-- Usage: :TodoHighlightPastDue
vim.api.nvim_create_user_command('TodoHighlightPastDue', function()
    todo_manager.highlight_past_due_dates()
    print("✓ Past due dates highlighted")
end, {
    desc = 'Manually highlight past due dates in red'
})

-- Debug what highlight group is applied at cursor
-- Usage: :TodoDebugHighlight
vim.api.nvim_create_user_command('TodoDebugHighlight', function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local result = vim.fn.synIDattr(vim.fn.synID(line, col + 1, 1), 'name')
    print("Highlight group at cursor: " .. (result or "none"))
    
    -- Also show all matches in the buffer
    local matches = vim.fn.getmatches()
    print("Active matches: " .. #matches)
    for i, match in ipairs(matches) do
        print("  " .. i .. ": " .. match.group .. " -> " .. match.pattern)
    end
end, {
    desc = 'Debug what highlight group is applied at cursor position'
})

-- Debug the dynamic highlighting function
-- Usage: :TodoDebugDynamic
vim.api.nvim_create_user_command('TodoDebugDynamic', function()
    local total_lines = vim.api.nvim_buf_line_count(0)
    print("Total lines: " .. total_lines)
    
    for line_num = 1, total_lines do
        local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
        if line then
            local due_date = line:match("%[Due:%s*([^%]]+)%]")
            if due_date then
                print("Line " .. line_num .. ": Found due date '" .. due_date .. "'")
                local cleaned = due_date:match("^%s*(.-)%s*$")
                print("  Cleaned: '" .. cleaned .. "'")
                
                -- Test the is_past_due function
                local is_past_due = function(date_str)
                    if not date_str or date_str == "" then return false end
                    local month, day, year = date_str:match("(%d+)-(%d+)-(%d+)")
                    if not month or not day or not year then return false end
                    local due_time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 23, min = 59, sec = 59})
                    local current_time = os.time()
                    return current_time > due_time
                end
                
                print("  Is past due: " .. tostring(is_past_due(cleaned)))
                print("  Pattern would be: \\[Due:\\s*" .. vim.pesc(cleaned) .. "\\]")
            end
        end
    end
end, {
    desc = 'Debug the dynamic highlighting function'
})

-- Apply working due date colors directly
-- Usage: :TodoFixColors
vim.api.nvim_create_user_command('TodoFixColors', function()
    vim.fn.clearmatches()
    
    -- Define strong colors
    vim.cmd('highlight! DuePastRed ctermfg=red cterm=bold guifg=#FF0000 gui=bold')
    vim.cmd('highlight! DueFutureYellow ctermfg=yellow cterm=bold guifg=#FFFF00 gui=bold')
    
    -- Hardcode the specific dates we know exist
    vim.fn.matchadd('DuePastRed', '\\[Due: 06-12-2025\\]', 1000)      -- Past due (red)
    vim.fn.matchadd('DueFutureYellow', '\\[Due: 07-21-2025\\]', 1000) -- Future (yellow)
    
    print("✓ Applied hardcoded due date colors")
end, {
    desc = 'Apply working due date colors directly'
})

-- Test highlighting by adding a simple red highlight to entire due date blocks
-- Usage: :TodoTestHighlight  
vim.api.nvim_create_user_command('TodoTestHighlight', function()
    vim.fn.clearmatches()
    vim.cmd('highlight TestRed ctermfg=red guifg=#FF0000')
    vim.cmd('highlight TestYellow ctermfg=yellow guifg=#FFFF00')
    
    -- Test pattern for entire due date blocks
    vim.fn.matchadd('TestRed', '\\[Due:[^\\]]*\\]', 100)
    print("✓ Added test red highlight to entire due date blocks")
end, {
    desc = 'Test if highlighting works for entire due date blocks'
})

-- Confirm successful loading of the todo system
print("✓ Vinod's Todo Manager loaded successfully!")