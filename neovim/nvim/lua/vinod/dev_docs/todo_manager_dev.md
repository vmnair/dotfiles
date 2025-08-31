# Todo Manager Development Documentation

## User Coding Preference
**Important**: I like to write code myself. Claude should show me the code with explanation and let me write the code so I can understand what I am doing. If I need Claude to update code or make changes, I will explicitly tell Claude to do so.

## System Overview

The todo manager is a comprehensive task management system built for Neovim with the following core files:
- **Main Logic**: `todo_manager.lua` (3094 lines) - Core functionality
- **Commands**: `config/todo_commands.lua` (1079 lines) - User commands and keybindings  
- **Plugin**: `plugins/todo-comments.lua` (11 lines) - Standard todo-comments plugin

## Core Data Structures

### Todo Object
```lua
{
    completed = false,           -- boolean
    description = "Task text",   -- string
    category = "Personal",       -- string (Medicine|OMS|Personal)
    tags = {"urgent", "health"}, -- array of strings
    due_date = "08-30-2025",    -- mm-dd-yyyy string
    show_date = "08-28-2025",   -- mm-dd-yyyy string  
    added_date = "08-30-2025",  -- mm-dd-yyyy string
    completion_date = "",        -- mm-dd-yyyy string (when completed)
    raw_line = "original line"   -- original markdown line
}
```

### File Formats
#### Current Clean Format
```markdown
- [ ] 💊 Take morning medication [Show: 08-30-2025] [Due: 08-30-2025] #urgent #health (08-29-2025)
```

#### Legacy Pipe Format (still supported)
```markdown
- [ ] Take medication | Category: Medicine | Tags: #urgent | Due: 08-30-2025 | Show: 08-30-2025 | Added: 08-29-2025
```

## Data Storage & Configuration

### File Structure
- **Active Todos**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo/active-todos.md`
- **Completed Todos**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo/completed-todos.md`
- **Notebook Directory**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook` (for zk integration)

### Categories & Icons
- **Medicine**: 💊
- **OMS**: 🛠️  
- **Personal**: 🏡
- **Default**: 📝 (fallback icon)

### Date Format
- **Standard**: `mm-dd-yyyy` format throughout system
- **Display**: Various contexts (active, scheduled, storage)

## Key Commands & Keybindings (Updated 2025-07-29)

### Essential Commands
- `:TodoAdd <desc> | Show: mm-dd-yyyy | Due: mm-dd-yyyy` - Full syntax with show/due dates
- `:TodoAdd <desc> /show /due` - Sequential calendar pickers  
- `:TodoMed`, `:TodoOMS`, `:Todo` - Quick category additions with show/due date support
- `:TodoList` - List currently active (visible) todos
- `:TodoScheduled` - List all scheduled (future) todos with show dates
- `:TodoUpcoming [days]` - List todos scheduled for next N days (default 7)
- `:TodoStats` - Show comprehensive todo statistics

### Global Keybindings (work anywhere) - NEW CONSISTENT SCHEME
- `<leader>ta` - Quick add todo (opens :TodoAdd prompt)
- `<leader>tl` - List active todos  
- `<leader>to` - Open filtered view of active todos (main daily workflow)
- `<leader>ts` - Show todo statistics
- `<leader>tb` - Interactive todo builder with calendar picker
- `<leader>th` - Show todo help window
- `<leader>tr` - Open raw todos file (includes scheduled todos)
- `<leader>tcc` - Open completed todos file

### File-Specific Keybindings (in todo files only)
- `tt` - Toggle completion in todo files (works in filtered view and raw files)
- `<leader>tc` - Create zk note from todo
- `<leader>td` - Update due date with calendar picker

### View/Filter Keybindings (in todo files only)
- `<leader>tvm` - Filter Medicine todos
- `<leader>tvo` - Filter OMS todos  
- `<leader>tvp` - Filter Personal todos
- `<leader>tva` - Show all todos (remove filters)
- `<leader>tvd` - Filter todos with due dates
- `<leader>tvt` - Filter todos due today
- `<leader>tvx` - Filter urgent todos (today + past due)
- `<leader>tvq` - Close filter window

## Features
- Category-based todos (Medicine 💊, OMS 🛠️, Personal 🏡)
- Future reminders: Schedule todos to appear on specific dates
- Smart due date highlighting (red for overdue, green for today, gray for future)
- Auto-refresh when adding/completing todos (filtered view updates immediately)
- Filtering by category, due dates, and show dates
- Syntax highlighting: Show dates in cyan/teal, due dates with color-coded urgency
- Index-based operations work correctly with filtered views
- Toggle functionality: `tt` works in both filtered and raw views with full sync
- Completed todo reactivation: Use `tt` in completed todos file to bring back to active

## Daily Workflow (Updated with new keybindings)
1. **Morning Review**: `<leader>to` - See only current active todos (filtered view)
2. **Add New Todos**: `<leader>ta` or `:Todo description /show mm-dd-yyyy /due mm-dd-yyyy` 
3. **Complete Todos**: Press `tt` on any todo line (works in filtered view)
4. **Check Upcoming**: `:TodoScheduled` or `:TodoUpcoming [days]`
5. **Reactivate Completed**: `<leader>tcc` then `tt` on completed todo
6. **View All (Admin)**: `<leader>tr` - See all todos including scheduled
7. **Quick Help**: `<leader>th` - Show comprehensive help window

## Recent Changes

### Todo Manager Keybinding Optimization (2025-07-29)

**Summary**: Implemented consistent keybinding scheme and reduced command namespace pollution.

**Changes Made**:
1. **Consistent Keybinding Prefix**: All todo keybindings now use `<leader>t*` pattern
   - **Global keybindings**: `<leader>ta` (add), `<leader>tl` (list), `<leader>to` (open), `<leader>ts` (stats), `<leader>tb` (build), `<leader>th` (help)
   - **File-specific actions**: `<leader>tc` (create note), `<leader>td` (update due date)
   - **View/Filter submenu**: `<leader>tv*` pattern (tvm, tvp, tvo, tva, tvd, tvt, tvx, tvq)

2. **Resolved Keybinding Conflicts**: 
   - `<leader>cd` → `<leader>td` (update due date - no conflict with "change directory")
   - `<leader>cn` → `<leader>tc` (create note - follows consistent pattern)
   - All filtering moved from `<leader>v*` to `<leader>tv*` (organized submenu)

3. **Command Namespace Cleanup**: Reduced from 22 to 8 essential commands
   - **Removed redundant commands**: TodoDue, TodoPastDue, TodoToday, TodoTodayAndPastDue, TodoComplete, TodoDelete, TodoCleanup, TodoToggle, TodoNote, and others
   - **Kept essential commands**: TodoAdd, Todo, TodoMed, TodoOMS, TodoList, TodoOpen, TodoHelp, TodoStats
   - **Replaced with keybindings**: All filtering and file operations now use consistent keybindings

### Todo Manager Buffer Modifiability Fix (2025-07-29)

**Issue**: When using `<leader>td` to update due dates via calendar picker, users encountered error `E5108: Buffer is not 'modifiable'` when working in filtered todo views.

**Solution**: Enhanced the function with buffer modifiability management:
- **Temporary Modifiability**: Checks buffer's modifiable state and temporarily enables modification if needed
- **State Restoration**: Restores original modifiable state after update
- **Dual Update Logic**: When working in filtered views, also updates the actual todo file to maintain data consistency

## Future Reminders Feature (Added 2025-01-27)
- **Show Date System**: Todos can be scheduled for future dates and only appear in active list when their show date arrives
- **Smart Defaults**: If only show date provided, due date auto-sets to same value
- **File Format**: `- [ ] [icon] Description [Show: mm-dd-yyyy] [Due: mm-dd-yyyy] #tags`
- **Display Logic**: 
  - Active list: Hides show dates (clean display)
  - Scheduled list: Shows both show and due dates
- **Core Functions**:
  - `get_active_todos()` - Only shows todos whose show date has arrived
  - `get_scheduled_todos()` - Shows future todos not yet active
  - `get_upcoming_todos(days)` - Shows todos scheduled for next N days

## Core Functionality Groups

### 1. File Operations (Lines 304-351)
- `read_todos_from_file(filename)` - Parse todos from markdown file
- `write_todos_to_file(filename, todos, header, context)` - Write todos with context-aware formatting
- `get_file_path(filename)` - Get full path for todo files

### 2. Todo Retrieval (Lines 352-441)
- `get_all_todos_from_active_file()` - All todos regardless of show date
- `get_active_todos()` - Only todos whose show date has arrived
- `get_completed_todos()` - All completed todos
- `get_scheduled_todos()` - Future todos not yet active
- `get_upcoming_todos(days)` - Scheduled for next N days

### 3. Date Utilities (Lines 443-581)
#### Date Validation
- `is_past_due(date_str)` - Check if date is past due
- `is_due_today(date_str)` - Check if date is today
- `is_show_date_reached(date_str)` - Check if show date has arrived

#### Date Shortcuts & Parsing
- `resolve_date_shortcut(keyword)` - Convert keywords to dates
- `calculate_future_date(amount, unit)` - Dynamic date calculation
- **Supported Patterns**:
  - Numbers: `1-12` with `days/weeks/months/years`
  - Words: `one-twelve` with time units
  - Special: `today`, `tomorrow`, `next week`, `this weekend`

### 4. Todo Management (Lines 584-977)
- `add_todo(description, category, tags, due_date, show_date)` - Add new todo
- `complete_todo(index)` - Complete and move to completed file
- `delete_todo(index)` - Permanently delete todo
- `cleanup_completed_todos()` - Move completed todos from active to completed file
- `init_todo_files()` - Initialize directory and files

### 5. Buffer Management (Lines 645-789)
- `save_active_todos_buffer_if_modified()` - Auto-save unsaved changes
- `refresh_active_todos_if_open()` - Refresh active todos file if open
- `refresh_filtered_view_if_open()` - Refresh filtered view buffers

### 6. Interactive Views (Lines 978-1161)
- `open_filtered_active_view()` - Main filtered view for daily use
- `toggle_todo_in_filtered_view()` - Toggle completion in filtered views

### 7. Buffer Filtering (Lines 1598-2342)
Multiple scratch buffer functions for interactive filtering:
- `filter_buffer_by_due_dates()` - Interactive due date filtering
- `filter_buffer_by_category(category)` - Interactive category filtering  
- `show_all_todos()` - Show all todos in scratch buffer
- `filter_buffer_by_today()` - Today's todos in scratch buffer
- `filter_buffer_by_past_due()` - Past due todos in scratch buffer
- `filter_buffer_by_today_and_past_due()` - Urgent todos in scratch buffer

### 8. ZK Integration (Lines 1369-1521)
- `get_notebook_directories()` - Scan notebook for directories
- `suggest_directory_for_category(category)` - Map categories to directories
- `create_note_from_todo()` - Create zk note from todo with directory selection

### 9. Date Picker (Lines 2605-2916)
- `show_date_picker(callback)` - Interactive floating calendar
- `get_date_input(callback)` - Wrapper for date picker
- `update_todo_date_on_line()` - Update due date with calendar picker
- **Navigation**: h/l (months), j/k (days), H/L (years), Enter/ESC/q

### 10. Syntax Highlighting (Lines 2988-3094)
- `setup_todo_syntax()` - Configure markdown syntax for todo files
- `highlight_due_dates_with_colors()` - Dynamic due date coloring
  - **Past Due**: Red (#DC143C)
  - **Due Today**: Green (#228B22)  
  - **Future**: Gray (#767676)
- **Other Highlights**: Completed todos (gray), hashtags (blue), show dates (cyan)

## Code Complexity Analysis

### High Complexity Areas (Candidates for Refactoring)

1. **Buffer Filtering Functions (Lines 1598-2342)** - 744 lines
   - 6 nearly identical filter functions with repetitive code
   - Each function: collect todos → create scratch buffer → setup keybindings
   - **Opportunity**: Extract common filtering pattern

2. **Todo Parsing (Lines 137-261)** - 124 lines
   - Supports both legacy pipe format and new clean format
   - Complex regex patterns for different syntaxes
   - **Opportunity**: Simplify to single format or extract parsers

3. **Command Argument Parsing (Lines 21-151)** - 130 lines
   - Complex nested logic for /show, /due, calendar flags
   - Duplicate error handling code
   - **Opportunity**: Extract argument parser utility

4. **Continuation Workflow (Lines 2344-2603)** - 259 lines
   - Complex state management for async calendar workflows
   - Duplicate logic between show/due continuation
   - **Opportunity**: Unify continuation handlers

5. **Date Picker (Lines 2605-2916)** - 311 lines
   - Large function with complex calendar rendering
   - Repetitive keymap setup code
   - **Opportunity**: Extract calendar widget

### Refactoring Recommendations

#### Phase 1: Extract Common Patterns
1. **Buffer Filter Pattern**: Create generic `create_filtered_buffer(todos, title, filter_type)` 
2. **Argument Parser**: Extract `parse_command_args(args)` utility
3. **Date Validation**: Consolidate date checking functions

#### Phase 2: Simplify Core Functions  
1. **Todo Parsing**: Consider dropping legacy pipe format support
2. **Continuation Workflow**: Unify show/due continuation logic
3. **Calendar Widget**: Extract reusable date picker component

#### Phase 3: Optimize Performance
1. **Reduce Function Count**: 50+ functions in single file
2. **Module Separation**: Split into logical modules
3. **Error Handling**: Consolidate error messages and validation

## Current Statistics
- **Total Lines**: ~4173 lines across 3 files
- **Functions**: 50+ functions in todo_manager.lua
- **Commands**: 8 essential + 8 support commands
- **Keybindings**: 20+ keybindings across 3 scopes

## Recent Development Updates

### TodoBuild Modal Dialog Implementation (2025-08-31)

**✅ COMPLETED**: Replaced sequential TodoBuild with an improved modal dialog showing all options on one screen.

**Changes Implemented**:
1. **Improved Modal Layout**:
   - Removed unnecessary "Add new todo" header
   - Increased dialog height from 15 to 20 lines for better visibility of control instructions
   - Fixed cursor positioning to start after "Description: " with proper spacing

2. **Enhanced User Experience**:
   - Description field now has consistent spacing with other labels (`" Description:  "`)
   - Cursor properly positioned after the space when entering insert mode
   - Fixed text capture issue where typed description disappeared on ESC
   - Flexible pattern matching handles varying whitespace after field labels

3. **Modal Controls** (accessible from `<leader>tb`):
   - **[i]** - Edit description inline (cursor positioned after space)
   - **[j/k]** - Navigate category selection (Medicine/OMS/Personal)
   - **[Enter]** - Context-sensitive: set dates when on date fields, submit otherwise
   - **[Tab]** - Navigate between form fields
   - **[s]** - Submit form from anywhere
   - **[ESC/q]** - Cancel and close modal

**Technical Fixes**:
- Pattern matching: Uses `" Description:%s*(.*)"` for flexible whitespace handling
- Cursor positioning: Position 15 accounts for `" Description:  "` (15 characters)
- Buffer management: Proper modifiable state handling during text entry
- Line number adjustments: Updated all references after removing header lines

This addresses the 99% use case of adding todos from anywhere in the terminal with a more efficient interface.

### Code Refactoring and Cleanup (2025-08-31)

**🔄 IN PROGRESS**: Major code cleanup to reduce duplication and improve maintainability.

**Analysis Results**:
- **Total file size**: ~3094 lines with significant duplication
- **Potential reduction**: ~400-500 lines (15-20% of file)
- **Major duplication areas**: 6 buffer filtering functions, continuation workflows, date picker patterns

**Refactoring Plan**:

**Phase 1: Buffer Filter Pattern Consolidation** 
- **Target**: Lines 1598-2342 (6 functions with ~600 lines of duplication)
- **Impact**: Reduce to ~200 lines (66% reduction)
- **Functions affected**: 
  - `filter_buffer_by_due_dates()` → consolidated utility
  - `filter_buffer_by_category()` → consolidated utility  
  - `show_all_todos()` → consolidated utility
  - `filter_buffer_by_today()` → consolidated utility
  - `filter_buffer_by_past_due()` → consolidated utility
  - `filter_buffer_by_today_and_past_due()` → consolidated utility
- **New utilities**: 
  - `create_filter_buffer(todos, title, filter_type)`
  - `setup_filter_keymaps(buf, todos, refresh_function)`
  - `collect_todos_with_filter(filter_function)`

**Phase 2: Date Picker Logic Consolidation**
- **Target**: 8 duplicate date picker invocations (~120 lines)
- **Impact**: Reduce to ~40 lines (67% reduction)
- **New utility**: `handle_date_picker_with_callback(callback, error_message)`

**Phase 3: Continuation Workflow Merge**
- **Target**: Lines 2344-2603 (show/due continuation duplication)
- **Impact**: Reduce ~250 lines to ~100 lines (60% reduction)  
- **Merge**: `process_continuation()` + `process_show_continuation()` → unified function

**Backup Plan**: All changes tracked with git commits for easy rollback if issues arise.

**Phase 1 Progress - Buffer Filter Pattern Consolidation** ✅ **PARTIALLY COMPLETED**

**✅ Achievements**:
- **Created 3 utility functions** (lines 1603-1739):
  - `collect_todos_with_filter(filter_function)` - Unified todo collection with flexible filtering
  - `create_filter_buffer(todos, title, filter_type, source_file)` - Standardized buffer creation
  - `setup_filter_keymaps(buf, todos)` - Consistent keymap setup across all filter functions
- **Successfully refactored 3 functions**:
  - `filter_buffer_by_due_dates()` - Reduced from ~130 lines to 8 lines (94% reduction)
  - `filter_buffer_by_category()` - Reduced from ~140 lines to 22 lines (preserves validation logic)
  - `show_all_todos()` - Reduced from ~120 lines to 8 lines (93% reduction)

**🔄 Remaining Work**:
- Clean up leftover code from incomplete replacements 
- Refactor remaining 3 functions: `filter_buffer_by_today()`, `filter_buffer_by_past_due()`, `filter_buffer_by_today_and_past_due()`

**Impact So Far**: Reduced ~390 lines to ~38 lines in refactored functions (90% reduction in targeted area)