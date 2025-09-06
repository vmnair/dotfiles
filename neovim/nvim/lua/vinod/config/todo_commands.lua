-- =====================================================
-- Neovim Commands and Keybindings for Vinod's Todo Manager
-- =====================================================
-- This file defines all user commands and key mappings for the todo system
-- Commands are organized by functionality: adding, listing, managing, and viewing todos
-- Key mappings are set up for todo files to enable spacebar toggling and filtering

local todo_manager = require("vinod.todo_manager")

-- Initialize the todo system when this module loads
-- Creates necessary directories and files if they don't exist
todo_manager.init_todo_files()

-- Parse user input for the TodoAdd command
-- Handles multiple syntaxes:
-- 1. Pipe syntax: "Description | Category: Medicine | Tags: #tag1 | Due: 07-20-2025 | Show: 07-18-2025"
-- 2. Direct hashtag: "Description #tag1 #tag2 | Category: Medicine | Due: 07-20-2025"
-- 3. Mixed syntax: "Description #urgent | Tags: #pharmacy | Category: Medicine"
-- Also handles calendar pickers: "Description #tag /show /due" or "Description | Category: Medicine /show"
-- Returns: description, category, tags array, due_date, show_date, use_show_calendar, use_due_calendar
local function parse_add_todo_args(args)
  local description = ""
  local category = ""
  local tags = {}
  local due_date = ""
  local show_date = ""
  local use_show_calendar = false
  local use_due_calendar = false

  -- Check for /show and /due with optional keywords
  -- Pattern: /show [keyword] or /due [keyword]
  -- Process both /show and /due independently
  
  -- First check for /show with keywords
  local show_match = args:match("%s*/show%s+([^/|]+)")
  if show_match then
    local keyword = vim.trim(show_match)
    local resolved_date = todo_manager.resolve_date_shortcut(keyword)
    if resolved_date then
      show_date = resolved_date
      -- Remove the /show keyword from args
      args = args:gsub("%s*/show%s+[^/|]+", "")
    else
      print("Error: Unrecognized show date shortcut '" .. keyword .. "'")
      print("Available patterns: [1-12 or one-twelve] [days/weeks/months/years]")
      print("Special shortcuts: today, tomorrow, next week, this weekend")
      return "", "", {}, "", "", false, false
    end
  elseif args:match("%s*/show%s*$") or args:match("%s*/show%s*[|]") then
    -- /show without keyword - use calendar picker
    use_show_calendar = true
    args = args:gsub("%s*/show%s*", "") -- Remove /show flag
  end

  -- Then check for /due with keywords
  local due_match = args:match("%s*/due%s+([^/|]+)")
  if due_match then
    local keyword = vim.trim(due_match)
    local resolved_date = todo_manager.resolve_date_shortcut(keyword)
    if resolved_date then
      due_date = resolved_date
      -- Remove the /due keyword from args
      args = args:gsub("%s*/due%s+[^/|]+", "")
    else
      print("Error: Unrecognized due date shortcut '" .. keyword .. "'")
      print("Available patterns: [1-12 or one-twelve] [days/weeks/months/years]") 
      print("Special shortcuts: today, tomorrow, next week, this weekend")
      return "", "", {}, "", "", false, false
    end
  elseif args:match("%s*/due%s*$") or args:match("%s*/due%s*[|]") then
    -- /due without keyword - use calendar picker
    use_due_calendar = true
    args = args:gsub("%s*/due%s*", "") -- Remove /due flag
  end

  -- Backward compatibility: /cal defaults to /due behavior
  if args:match("%s*/cal%s*") then
    use_due_calendar = true
    args = args:gsub("%s*/cal%s*", "") -- Remove /cal flag
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
    elseif part:match("^[Ss]how:") then
      show_date = part:match("^[Ss]how:%s*(.+)$")
    end
  end

  return description, category, tags, due_date, show_date, use_show_calendar, use_due_calendar
end

-- ================
-- ADDING COMMANDS
-- ================

-- Interactive todo builder command
-- Usage: :TodoBuild to start interactive todo building process

vim.api.nvim_create_user_command("TodoBuild", function()
  todo_manager.show_todo_modal()
end, {
  desc = "Interactive todo builder with modal dialog",
})
-- Main command for adding todos with full metadata support
-- Usage examples:
--   :TodoAdd Buy medicine #urgent #pharmacy | Category: Medicine | Due: 07-20-2025
--   :TodoAdd Buy medicine #urgent | Category: Medicine /cal
--   :TodoAdd Meeting with doctor #important /cal
-- Calendar picker: Use /cal suffix to select date with calendar
-- All fields except description are optional
-- Category defaults to "Personal" if not specified
vim.api.nvim_create_user_command("TodoAdd", function(opts)
  local args = opts.args
  if args == "" then
    print(
      "Usage: :TodoAdd <description> [#tag1 #tag2] [| Category: <category>] [| Due: mm-dd-yyyy] [| Show: mm-dd-yyyy]"
    )
    print("Date shortcuts: Use /show [keyword] or /due [keyword] with:")
    print("  Pattern: [1-12 or one-twelve] [days/weeks/months/years]")
    print("  Special: today, tomorrow, next week, this weekend")
    print("Examples: TodoAdd Buy medicine #urgent | Category: Medicine")
    print("         TodoAdd Meeting prep #work /show /due")
    print("         TodoAdd Buy groceries /show tomorrow")
    print("         TodoAdd Doctor visit /due next week")
    print("         TodoAdd Project deadline /show this weekend /due 1 month")
    print("         TodoAdd Call dentist /show 3 days")
    print("         TodoAdd Review /due five weeks")
    print("         TodoAdd Annual checkup /show 1 year")
    print("Calendar: Use /show or /due alone to open date picker")
    print("Note: Category defaults to 'Personal' if not specified")
    return
  end

  local description, category, tags, due_date, show_date, use_show_calendar, use_due_calendar =
      parse_add_todo_args(args)

  if description == "" then
    print("Error: Description is required")
    return
  end

  -- Always default to Personal category for TodoAdd command
  if not category or category == "" then
    category = "Personal"
  end

  -- Apply date logic rules:
  -- 1. If /show is used without /due, set both to show value  
  -- 2. If /due is used without /show, keep command line active for continuation
  if show_date ~= "" and due_date == "" and not use_due_calendar then
    -- Show date provided without due date - set both to same value
    due_date = show_date
  elseif (due_date ~= "" or use_due_calendar) and show_date == "" and not use_show_calendar then
    -- Due date specified but no show date required
    if use_due_calendar then
      -- /due without keyword - show calendar picker first, then continuation
      todo_manager.get_date_input(function(picked_due_date)
        if picked_due_date then
          due_date = picked_due_date
        else
          due_date = os.date("%m-%d-%Y") -- fallback to today
        end
        
        -- Now that we have due date, prompt for show date
        vim.ui.input({ 
          prompt = ":TodoAdd " .. description .. " [Due: " .. due_date .. "] ",
          default = "/show "
        }, function(input)
          if input and input:match("/show") then
            -- Parse the /show part
            local show_match = input:match("/show%s+([^/|]+)")
            if show_match then
              local keyword = vim.trim(show_match)
              local resolved_date = todo_manager.resolve_date_shortcut(keyword)
              if resolved_date then
                show_date = resolved_date
              else
                show_date = os.date("%m-%d-%Y") -- fallback to today
              end
            else
              -- Just /show without keyword - use calendar picker
              todo_manager.get_date_input(function(picked_show_date)
                if picked_show_date then
                  show_date = picked_show_date
                else
                  show_date = os.date("%m-%d-%Y")
                end
                -- Add todo with both dates
                local success = todo_manager.add_todo(description, category, tags, due_date, show_date)
                if success then
                  print("✓ Todo added: " .. description .. " (Personal) [Show: " .. show_date .. "] [Due: " .. due_date .. "]")
                end
              end)
              return
            end
          else
            print("Todo cancelled. Use /show to set show date.")
            return
          end
          
          -- Add todo with both dates
          local success = todo_manager.add_todo(description, category, tags, due_date, show_date)
          if success then
            print("✓ Todo added: " .. description .. " (Personal) [Show: " .. show_date .. "] [Due: " .. due_date .. "]")
          end
        end)
      end)
      return
    else
      -- /due with keyword - due_date already set, just prompt for show date
      vim.ui.input({ 
        prompt = ":TodoAdd " .. description .. " [Due: " .. due_date .. "] ",
        default = "/show "
      }, function(input)
        if input and input:match("/show") then
          -- Parse the /show part
          local show_match = input:match("/show%s+([^/|]+)")
          if show_match then
            local keyword = vim.trim(show_match)
            local resolved_date = todo_manager.resolve_date_shortcut(keyword)
            if resolved_date then
              show_date = resolved_date
            else
              show_date = os.date("%m-%d-%Y") -- fallback to today
            end
          else
            -- Just /show without keyword - use calendar picker
            todo_manager.get_date_input(function(picked_show_date)
              if picked_show_date then
                show_date = picked_show_date
              else
                show_date = os.date("%m-%d-%Y")
              end
              -- Add todo with both dates
              local success = todo_manager.add_todo(description, category, tags, due_date, show_date)
              if success then
                print("✓ Todo added: " .. description .. " (Personal) [Show: " .. show_date .. "] [Due: " .. due_date .. "]")
              end
            end)
            return
          end
        else
          print("Todo cancelled. Use /show to set show date.")
          return
        end
        
        -- Add todo with both dates
        local success = todo_manager.add_todo(description, category, tags, due_date, show_date)
        if success then
          print("✓ Todo added: " .. description .. " (Personal) [Show: " .. show_date .. "] [Due: " .. due_date .. "]")
        end
      end)
      return
    end
  end

  -- Handle command continuation workflow
  local handled = todo_manager.handle_command_continuation(
    description,
    category,
    tags,
    due_date,
    show_date,
    use_show_calendar,
    use_due_calendar,
    ":TodoAdd"
  )

  if not handled then
    -- No calendar pickers, add todo directly
    local success = todo_manager.add_todo(description, category, tags, due_date, show_date)
    if success then
      local cat_display = category and category ~= "" and category or "Personal"
      local show_display = show_date and show_date ~= "" and " [Show: " .. show_date .. "]" or ""
      local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
      print("✓ Todo added: " .. description .. " (" .. cat_display .. ")" .. show_display .. due_display)
    else
      print("✗ Failed to add todo")
    end
  end
end, {
  nargs = "*",
  desc = "Add a new todo with hashtag syntax support (use /show or /due for calendar picker)",
})

-- Quick command for adding Personal category todos (most common use case)
-- Usage examples:
--   :Todo Buy groceries #urgent | Due: 07-25-2025
--   :Todo Buy groceries #urgent /cal
--   :Todo Meeting preparation #work
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "Personal", supports hashtag syntax and due dates
vim.api.nvim_create_user_command("Todo", function(opts)
  local args = opts.args
  if args == "" then
    print("Usage: :Todo <description> [#tag1 #tag2] [| Due: mm-dd-yyyy] [| Show: mm-dd-yyyy]")
    print("Examples: Todo Buy groceries #urgent")
    print("         Todo Call dentist #health /show /due")
    print("Calendar: Add /show or /due suffix to use date picker")
    print("Creates a Personal category todo")
    return
  end

  local description, _, tags, due_date, show_date, use_show_calendar, use_due_calendar = parse_add_todo_args(args)

  if description == "" then
    print("Error: Description is required")
    return
  end

  -- Handle command continuation workflow
  local handled = todo_manager.handle_command_continuation(
    description,
    "Personal",
    tags,
    due_date,
    show_date,
    use_show_calendar,
    use_due_calendar,
    ":Todo"
  )

  if not handled then
    -- No calendar pickers, add todo directly
    local success = todo_manager.add_todo(description, "Personal", tags, due_date, show_date)
    if success then
      local show_display = show_date and show_date ~= "" and " [Show: " .. show_date .. "]" or ""
      local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
      print("✓ Personal todo added: " .. description .. show_display .. due_display)
    else
      print("✗ Failed to add todo")
    end
  end
end, {
  nargs = "*",
  desc = "Quick add a Personal category todo with hashtag syntax (use /cal for calendar)",
})

-- Quick command for adding Medicine category todos
-- Usage examples:
--   :TodoMed Take medication #urgent | Due: 07-25-2025
--   :TodoMed Take medication #urgent /cal
--   :TodoMed Doctor appointment #followup
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "Medicine", supports hashtag syntax and due dates
vim.api.nvim_create_user_command("TodoMed", function(opts)
  local args = opts.args
  if args == "" then
    print("Usage: :TodoMed <description> [#tag1 #tag2] [| Due: mm-dd-yyyy] [| Show: mm-dd-yyyy]")
    print("Examples: TodoMed Take medication #morning")
    print("         TodoMed Doctor appointment #followup /show /due")
    print("Calendar: Add /show or /due suffix to use date picker")
    return
  end

  local description, _, tags, due_date, show_date, use_show_calendar, use_due_calendar = parse_add_todo_args(args)

  if description == "" then
    print("Error: Description is required")
    return
  end

  -- Handle command continuation workflow
  local handled = todo_manager.handle_command_continuation(
    description,
    "Medicine",
    tags,
    due_date,
    show_date,
    use_show_calendar,
    use_due_calendar,
    ":TodoMed"
  )

  if not handled then
    -- No calendar pickers, add todo directly
    local success = todo_manager.add_todo(description, "Medicine", tags, due_date, show_date)
    if success then
      local show_display = show_date and show_date ~= "" and " [Show: " .. show_date .. "]" or ""
      local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
      print("✓ Medicine todo added: " .. description .. show_display .. due_display)
    else
      print("✗ Failed to add todo")
    end
  end
end, {
  nargs = "*",
  desc = "Quick add a Medicine category todo with hashtag syntax (use /cal for calendar)",
})

-- Quick command for adding OMS category todos
-- Usage examples:
--   :TodoOMS Review patient charts #urgent | Due: 07-25-2025
--   :TodoOMS Review patient charts #urgent /cal
--   :TodoOMS Update documentation #priority
-- Calendar: Use /cal suffix to select date with calendar
-- Automatically sets category to "OMS", supports hashtag syntax and due dates
vim.api.nvim_create_user_command("TodoOMS", function(opts)
  local args = opts.args
  if args == "" then
    print("Usage: :TodoOMS <description> [#tag1 #tag2] [| Due: mm-dd-yyyy] [| Show: mm-dd-yyyy]")
    print("Examples: TodoOMS Review charts #urgent")
    print("         TodoOMS Update system #maintenance /show /due")
    print("Calendar: Add /show or /due suffix to use date picker")
    return
  end

  local description, _, tags, due_date, show_date, use_show_calendar, use_due_calendar = parse_add_todo_args(args)

  if description == "" then
    print("Error: Description is required")
    return
  end

  -- Handle command continuation workflow
  local handled = todo_manager.handle_command_continuation(
    description,
    "OMS",
    tags,
    due_date,
    show_date,
    use_show_calendar,
    use_due_calendar,
    ":TodoOMS"
  )

  if not handled then
    -- No calendar pickers, add todo directly
    local success = todo_manager.add_todo(description, "OMS", tags, due_date, show_date)
    if success then
      local show_display = show_date and show_date ~= "" and " [Show: " .. show_date .. "]" or ""
      local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]" or ""
      print("✓ OMS todo added: " .. description .. show_display .. due_display)
    else
      print("✗ Failed to add todo")
    end
  end
end, {
  nargs = "*",
  desc = "Quick add an OMS category todo with hashtag syntax (use /cal for calendar)",
})

-- ================
-- LISTING COMMANDS
-- ================

-- List all active todos with optional category filtering
-- Usage: :TodoList [category]
-- Shows numbered list suitable for use with TodoComplete/TodoDelete
vim.api.nvim_create_user_command("TodoList", function(opts)
  local category = opts.args ~= "" and opts.args or nil
  todo_manager.list_active_todos(category)
end, {
  nargs = "?",
  desc = "List active todos, optionally filtered by category",
})

-- List all completed todos with optional category filtering
-- Removed TodoCompleted and TodoCategory commands - functionality not implemented
-- Use <leader>tcc to open completed todos file directly
-- Use <leader>tvm, <leader>tvo, <leader>tvp for category filtering in active view

-- List all scheduled (future) todos
-- Usage: :TodoScheduled
vim.api.nvim_create_user_command("TodoScheduled", function()
  local scheduled_todos = todo_manager.get_scheduled_todos()
  todo_manager.display_todos(scheduled_todos, "Scheduled (Future) Todos")
end, {
  desc = "List all scheduled todos with future show dates",
})

-- List upcoming todos (next 7 days)
-- Usage: :TodoUpcoming [days]
vim.api.nvim_create_user_command("TodoUpcoming", function(opts)
  local days = tonumber(opts.args) or 7
  local upcoming_todos = todo_manager.get_upcoming_todos(days)
  todo_manager.display_todos(upcoming_todos, "Upcoming Todos (Next " .. days .. " Days)")
end, {
  nargs = "?",
  desc = "List todos scheduled for the next N days (default 7)",
})

-- ===================
-- MANAGEMENT COMMANDS
-- ===================

-- =====================
-- FILE ACCESS COMMANDS
-- =====================

-- Open the active todos file for editing
-- Opens active-todos.md in current window
vim.api.nvim_create_user_command("TodoOpen", function()
  todo_manager.open_filtered_active_view()
end, {
  desc = "Open filtered view of active todos (only shows todos whose show date has arrived)",
})

-- ====================
-- INFORMATION COMMANDS
-- ====================

-- Show comprehensive todo statistics
-- Displays counts by category for both active and completed todos
vim.api.nvim_create_user_command("TodoStats", function()
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
  desc = "Show todo statistics",
})

-- ===================
-- Edit selected todo with pre-populated modal
-- Usage: :TodoEditSelected
vim.api.nvim_create_user_command("TodoEditSelected", function()
  todo_manager.edit_todo_modal()
end, {
  desc = "Edit the todo on the current cursor line",
})

-- MAINTENANCE COMMANDS
-- ===================

-- Display all todo manager keymaps in a floating window
-- Usage: :TodoHelp
vim.api.nvim_create_user_command("TodoHelp", function()
  local keymaps = {
    ["Essential Commands"] = {
      [":TodoAdd <desc> [#tags] [| Category: <cat>] [| Due: mm-dd-yyyy] [| Show: mm-dd-yyyy]"] =
      "Add new todo with full metadata",
      [":TodoAdd <desc> /show /due"] = "Sequential calendar pickers for show and due dates",
      [":TodoAdd <desc> /show tomorrow"] = "Add todo with date shortcut (see shortcuts below)",
      [":Todo <desc> [#tags] /show /due"] = "Quick add Personal todo with both dates",
      [":TodoMed <desc> [#tags] /due next week"] = "Quick add Medicine todo with date shortcut",
      [":TodoOMS <desc> [#tags] /due this weekend"] = "Quick add OMS todo with date shortcut",
      [":TodoList [category]"] = "List currently active (visible) todos",
      [":TodoScheduled"] = "List all scheduled (future) todos with show dates",
      [":TodoUpcoming [days]"] = "List todos scheduled for next N days (default 7)",
      [":TodoStats"] = "Show comprehensive todo statistics",
    },
    ["Date Shortcuts"] = {
      ["Pattern: [1-12] [unit]"] = "Use numbers 1-12 with days/weeks/months/years",
      ["Pattern: [word] [unit]"] = "Use one-twelve with days/weeks/months/years",
      ["/show 5 days"] = "Show todo in 5 days",
      ["/due two weeks"] = "Due in 2 weeks (14 days)",
      ["/show 1 month"] = "Show todo in 30 days",
      ["/due twelve years"] = "Due in 12 years (4380 days)",
      ["/show today"] = "Show todo today (special case)",
      ["/due tomorrow"] = "Due tomorrow (special case)",
      ["/show next week"] = "Show todo in 1 week (alias)",
      ["/due this weekend"] = "Due this Saturday (special case)",
      ["/show (no keyword)"] = "Opens calendar picker for manual date selection",
    },
    ["Global Keybindings (work anywhere)"] = {
      ["<leader>ta"] = "Quick add todo (opens :TodoAdd prompt)",
      ["<leader>tl"] = "List active todos",
      ["<leader>to"] = "Open filtered view of active todos (main workflow)",
      ["<leader>ts"] = "Show todo statistics",
      ["<leader>tb"] = "Interactive todo builder modal (all fields on one screen)",
      ["<leader>th"] = "Show this help window",
      ["<leader>tr"] = "Open raw todos file (includes scheduled todos)",
      ["<leader>tc"] = "Open completed todos file",
    },
    ["File-Specific Keybindings (in todo files only)"] = {
      ["tt"] = "Toggle todo completion (works in filtered view & raw files)",
      ["<leader>tz"] = "Create or open zk note from todo (smart detection)",
      ["<leader>tc"] = "Open completed todos file", 
      ["<leader>td"] = "Update due date with calendar picker",
      ["<leader>te"] = "Edit todo with pre-populated modal",
    },
    ["Category Filtering"] = {
      [":TodoFilter Medicine"] = "Filter current view to show only Medicine todos",
      [":TodoFilter OMS"] = "Filter current view to show only OMS todos", 
      [":TodoFilter Personal"] = "Filter current view to show only Personal todos",
      [":TodoFilter Clear"] = "Remove filter and show all todos",
      ["<leader>tf"] = "Interactive filter menu with category selection",
      ["Smart Integration"] = "TodoBuilder pre-selects filtered category",
      ["Filter Persistence"] = "Filters maintained during todo operations",
    },
    ["TodoBuild Modal Controls (<leader>tb & <leader>te)"] = {
      ["i"] = "Edit description inline with proper cursor positioning",
      ["j/k"] = "Navigate category selection (Medicine/OMS/Personal)",
      ["Enter"] = "Context-sensitive: date picker on dates, submit on other fields",
      ["Tab"] = "Navigate between fields: Description → Category → Show → Due",
      ["s"] = "Submit form from anywhere",
      ["ESC/q"] = "Cancel and close modal",
    },
    ["Command-Line Continuation (/due workflow)"] = {
      [":Todo task /due → pick date → command line shows:"] = "':Todo task [Due: date] '",
      ["Press Enter"] = "Add todo with show_date = due_date",
      ["Type '/show' → pick date"] = "Add todo with both show and due dates",
      ["Type anything else"] = "Cancel todo creation",
    },
    ["Show Date System"] = {
      ["Active list (:TodoList)"] = "Hides show dates (clean display)",
      ["Scheduled list (:TodoScheduled)"] = "Shows show dates for future todos",
      ["/show with future date"] = "Todo scheduled (not in active list until show date)",
      ["/show only"] = "Auto-sets due_date = show_date",
      ["/due only"] = "Auto-sets show_date = due_date",
    },
    ["File Views"] = {
      [":TodoOpen"] = "Filtered view - only active todos (daily use)",
      [":TodoOpenRaw"] = "Raw file - all todos including scheduled (admin)",
      [":TodoOpenCompleted"] = "Completed todos file",
      ["Auto-refresh"] = "Filtered view updates immediately when todos change",
    },
    ["Reactivating Completed Todos"] = {
      [":TodoOpenCompleted"] = "Open completed todos file",
      ["tt on completed todo line"] = "Toggle back to incomplete (moves to active)",
      [":TodoCompleted"] = "List completed todos for reference",
    },
    ["ZK Integration (Zettelkasten Notes)"] = {
      ["<leader>tz"] = "Smart note integration: duplicate detection, open existing or create new",
      ["Duplicate detection"] = "Searches frontmatter for todo_id to find existing notes",
      ["Existing note found"] = "Opens existing note automatically, prompts for todo completion",
      ["No existing note"] = "Creates new note with structured template and unique todo_id",
      ["Note template includes"] = "Category, tags, dates, and original todo reference",
      ["After note interaction"] = "Optional prompt to mark todo as completed",
      ["Requirements"] = "zk command must be installed (brew install zk)",
    },
    ["Daily Workflow"] = {
      ["Morning"] = "<leader>to (filtered view for current todos)",
      ["Add todos"] = "<leader>tb (interactive builder) or <leader>ta",
      ["Filter focus"] = "<leader>tf (select category to focus on)",
      ["Edit todos"] = "<leader>te (edit current todo inline)",
      ["Create notes"] = "<leader>tz (create/open zk note from todo)",
      ["Complete"] = "tt on any todo line",
      ["Check upcoming"] = ":TodoScheduled or :TodoUpcoming",
      ["Quick help"] = "<leader>th (show this help)",
    },
    ["Calendar Picker"] = {
      ["h/l"] = "Previous/Next month",
      ["j/k"] = "Previous/Next day",
      ["H/L"] = "Previous/Next year",
      ["Enter"] = "Select date",
      ["q/ESC"] = "Cancel",
    },
  }

  -- Create floating window
  local width = 90
  local height = 35
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
    title_pos = "center",
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
  desc = "Show todo manager help with all commands and keybindings",
})

-- ========================
-- AUTO-COMMANDS AND KEYBINDINGS
-- ========================

-- Set up automatic behavior when entering todo files
-- Enables spacebar toggling and sets up keybindings
-- Applies to any .md file in the /todo/ directory
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*/todo/*.md" },
  callback = function()
    -- Map tt to toggle todo completion (primary interaction)
    -- Works on any line containing a todo item (normal mode only)
    vim.keymap.set("n", "tt", function()
      todo_manager.toggle_todo_on_line()
    end, {
      buffer = true,
      desc = "Toggle todo completion",
      silent = true,
    })

    -- ========================
    -- FILTERING KEYBINDINGS (CUSTOM BUFFER)
    -- ========================
    -- Custom buffer filtering system - clean display without quickfix clutter
    -- Opens a scratch buffer showing filtered todos with navigation

    -- Todo View/Filter Submenu - consistent <leader>tv* pattern
    -- Medicine category filter
    vim.keymap.set("n", "<leader>tvm", function()
      todo_manager.filter_buffer_by_category("Medicine")
    end, {
      buffer = true,
      desc = "Filter Medicine todos",
      silent = true,
    })

    -- Personal category filter
    vim.keymap.set("n", "<leader>tvp", function()
      todo_manager.filter_buffer_by_category("Personal")
    end, {
      buffer = true,
      desc = "Filter Personal todos",
      silent = true,
    })

    -- OMS category filter
    vim.keymap.set("n", "<leader>tvo", function()
      todo_manager.filter_buffer_by_category("OMS")
    end, {
      buffer = true,
      desc = "Filter OMS todos",
      silent = true,
    })

    -- Show all todos (no filtering)
    vim.keymap.set("n", "<leader>tva", function()
      todo_manager.show_all_todos()
    end, {
      buffer = true,
      desc = "Show all todos",
      silent = true,
    })

    -- Filter by due dates
    vim.keymap.set("n", "<leader>tvd", function()
      todo_manager.filter_buffer_by_due_dates()
    end, {
      buffer = true,
      desc = "Filter todos with due dates",
      silent = true,
    })

    -- Filter by today's due date
    vim.keymap.set("n", "<leader>tvt", function()
      todo_manager.filter_buffer_by_today()
    end, {
      buffer = true,
      desc = "Filter todos due today",
      silent = true,
    })

    -- Filter by today and past due
    vim.keymap.set("n", "<leader>tvx", function()
      todo_manager.filter_buffer_by_today_and_past_due()
    end, {
      buffer = true,
      desc = "Filter urgent todos (today + past due)",
      silent = true,
    })

    -- Close filter window
    vim.keymap.set("n", "<leader>tvq", function()
      vim.cmd("close")
      print("✓ Filter window closed")
    end, {
      buffer = true,
      desc = "Close filter window",
      silent = true,
    })

    -- Todo Actions - consistent <leader>t* pattern
    -- Update due date on current line using calendar picker
    vim.keymap.set("n", "<leader>td", function()
      todo_manager.update_todo_date_on_line()
    end, {
      buffer = true,
      desc = "Update due date with calendar picker",
      silent = true,
    })

    -- Create or open zk note from todo on current line  
    vim.keymap.set("n", "<leader>tz", function()
      todo_manager.create_or_open_note_from_todo()
    end, {
      buffer = true,
      desc = "Create or open zk note from todo",
      silent = true,
    })

    -- Open completed todos file
    vim.keymap.set("n", "<leader>tc", function()
      local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.completed_file
      vim.cmd("edit " .. file_path)
    end, {
      buffer = true,
      desc = "Open completed todos file",
      silent = true,
    })

    -- Edit todo on current line
    vim.keymap.set("n", "<leader>te", function()
      todo_manager.edit_todo_modal()
    end, {
      buffer = true,
      desc = "Edit todo on current line",
      silent = true,
    })

    -- Setup syntax highlighting for better visual appearance
    todo_manager.setup_todo_syntax()

    -- Also apply due date highlighting automatically
    todo_manager.highlight_due_dates_with_colors()
  end,
})

-- Add autocmds for real-time syntax highlighting updates
-- Reapply highlighting when buffer content changes
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = { "*/todo/*.md" },
  callback = function()
    -- Debounce: only refresh highlighting after a short delay
    vim.defer_fn(function()
      todo_manager.highlight_due_dates_with_colors()
    end, 200)
  end,
})

-- Also refresh highlighting when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = { "*/todo/*.md" },
  callback = function()
    todo_manager.highlight_due_dates_with_colors()
  end,
})

-- =============================
-- GLOBAL KEYBINDINGS - Consistent <leader>t* Pattern
-- =============================
-- Quick access to todo commands from anywhere in Neovim
-- All keybindings follow consistent two-letter pattern under <leader>t

-- Quick add todo with prompt
vim.keymap.set("n", "<leader>ta", ":TodoAdd ", { desc = "Add new todo" })

-- List active todos
vim.keymap.set("n", "<leader>tl", ":TodoList<CR>", { desc = "List active todos" })

-- Open filtered view of active todos (main daily workflow)
vim.keymap.set("n", "<leader>to", ":TodoOpen<CR>", { desc = "Open filtered active todos" })

-- Show todo statistics
vim.keymap.set("n", "<leader>ts", ":TodoStats<CR>", { desc = "Show todo statistics" })

-- Interactive todo builder
vim.keymap.set("n", "<leader>tb", ":TodoBuild<CR>", { desc = "Interactive todo builder" })

-- Show todo help
vim.keymap.set("n", "<leader>th", ":TodoHelp<CR>", { desc = "Show todo help" })

-- Category filter menu
vim.keymap.set("n", "<leader>tf", function()
  todo_manager.show_category_filter_menu()
end, { desc = "Show category filter menu" })

-- Additional file access keybindings - these need supporting commands
vim.keymap.set("n", "<leader>tr", ":TodoOpenRaw<CR>", { desc = "Open raw todos file (with scheduled)" })

-- Open completed todos file (moved from buffer-specific to global for convenience)
vim.keymap.set("n", "<leader>tc", ":TodoOpenCompleted<CR>", { desc = "Open completed todos file" })

-- ===============================
-- SUPPORTING COMMANDS FOR KEYBINDINGS
-- ===============================
-- These commands support the keybindings but are not meant for direct use

-- Open the raw active todos file for editing (includes scheduled todos)
vim.api.nvim_create_user_command("TodoOpenRaw", function()
  local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.active_file
  vim.cmd("edit " .. file_path)
end, {
  desc = "Open raw active todos file for editing (includes scheduled todos)",
})

-- Open the completed todos file for viewing
vim.api.nvim_create_user_command("TodoOpenCompleted", function()
  local file_path = todo_manager.config.todo_dir .. "/" .. todo_manager.config.completed_file
  vim.cmd("edit " .. file_path)
end, {
  desc = "Open the completed todos file for viewing",
})

-- ===============================
-- CATEGORY MANAGEMENT COMMANDS
-- ===============================

-- Add a new category with custom icon
-- Usage: :TodoAddCategory Work 💼
vim.api.nvim_create_user_command("TodoAddCategory", function(opts)
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
  nargs = "*",
  desc = "Add a new category with custom icon",
})

-- ===============================
-- CATEGORY FILTERING SYSTEM
-- ===============================

-- TodoFilter command for in-place category filtering
vim.api.nvim_create_user_command("TodoFilter", function(opts)
  local args = opts.args
  
  if args == "" then
    -- No args - show current filter status or open menu
    local current_filter = todo_manager.get_current_filter()
    if current_filter then
      print("Current filter: " .. current_filter)
      print("Use :TodoFilter Clear to show all todos")
    else
      print("No filter active - showing all todos")
      print("Use :TodoFilter [Category] or <leader>tf for menu")
    end
    return
  end
  
  -- Handle "Clear" command
  if args:lower() == "clear" then
    todo_manager.clear_category_filter()
    print("✓ Filter cleared - showing all todos")
    return
  end
  
  -- Validate category
  local valid, result = todo_manager.validate_category(args)
  if valid then
    todo_manager.set_category_filter(result)
    print("✓ Filter applied: " .. result)
  else
    print("✗ " .. result)
    -- Optionally show menu for correction
    print("Use <leader>tf to select from available categories")
  end
end, {
  nargs = "?",
  desc = "Filter todos by category (use Clear to show all)",
})

-- Category filter menu interface using vim.ui.select
function todo_manager.show_category_filter_menu()
  local counts = todo_manager.get_category_todo_counts()
  local current_filter = todo_manager.get_current_filter()
  
  -- Create menu options
  local options = {}
  local display_options = {}
  
  -- Add "Clear" option first
  local clear_marker = current_filter == nil and "● " or "○ "
  local clear_display = clear_marker .. "Clear (" .. counts["Clear"] .. " todos)"
  table.insert(options, "Clear")
  table.insert(display_options, clear_display)
  
  -- Add category options
  for _, category in ipairs(todo_manager.config.categories) do
    local marker = current_filter == category and "● " or "○ "
    local count = counts[category] or 0
    local icon = todo_manager.config.category_icons[category] or "📝"
    local display = marker .. category .. " " .. icon .. " (" .. count .. ")"
    table.insert(options, category)
    table.insert(display_options, display)
  end
  
  -- Use vim.ui.select for consistent interface
  vim.ui.select(options, {
    prompt = "Todo Category Filter:",
    format_item = function(item)
      -- Find the index of this item to get the display version
      for i, option in ipairs(options) do
        if option == item then
          return display_options[i]
        end
      end
      return item
    end,
  }, function(selected)
    if not selected then
      return -- User cancelled
    end
    
    if selected == "Clear" then
      todo_manager.clear_category_filter()
      print("✓ Filter cleared - showing all todos")
    else
      todo_manager.set_category_filter(selected)
      print("✓ Filter applied: " .. selected)
    end
  end)
end

-- Add TodoRemoveCategory command
vim.api.nvim_create_user_command("TodoRemoveCategory", function(opts)
  local args = opts.args
  if args == "" then
    print("Usage: :TodoRemoveCategory <category_name>")
    print("Available categories: " .. table.concat(todo_manager.config.categories, ", "))
    return
  end
  
  local success, message = todo_manager.remove_category_with_checks(args)
  if success then
    print("✓ " .. message)
  else
    print("✗ " .. message)
  end
end, {
  nargs = 1,
  desc = "Remove a category (requires all todos to be completed first)",
})

-- Available categories with their icons:
-- Medicine (💊), OMS (🛠️), Personal (🏡)
-- Icons are hardcoded in M.config.category_icons

-- Confirm successful loading of the todo system (silent load)

