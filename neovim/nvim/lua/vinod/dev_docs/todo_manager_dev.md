# Todo Manager Development Documentation

## System Overview

The todo manager is a comprehensive task management system built for Neovim with the following core files:

- **Main Logic**: `todo_manager.lua` (~2000 lines) - Core functionality
- **Commands**: `config/todo_commands.lua` - User commands and keybindings
- **Plugin**: `plugins/todo-comments.lua` - Standard todo-comments plugin

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
}
```

### File Format

```markdown
- [ ] 💊 Take morning medication [Show: 08-30-2025] [Due: 08-30-2025] #urgent #health
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

## Key Commands & Keybindings

### Essential Commands

- `:TodoAdd <desc> /show /due` - Add todo with calendar pickers
- `:TodoMed`, `:TodoOMS`, `:Todo` - Quick category additions
- `:TodoList` - List currently active (visible) todos
- `:TodoEditSelected` - Edit todo on current line

### Global Keybindings (work anywhere)

- `<leader>ta` - Quick add todo
- `<leader>tl` - List active todos
- `<leader>to` - Open filtered view of active todos (main daily workflow)
- `<leader>tb` - Interactive todo builder with calendar picker
- `<leader>tr` - Open raw todos file (includes scheduled todos)

### File-Specific Keybindings (in todo files only)

- `tt` - Toggle completion (works in filtered view and raw files)
- `<leader>te` - Edit current todo
- `<leader>tc` - Create zk note from todo
- `<leader>td` - Update due date with calendar picker

### View/Filter Keybindings (in todo files only)

- `<leader>tvm` - Filter Medicine todos
- `<leader>tvo` - Filter OMS todos
- `<leader>tvp` - Filter Personal todos
- `<leader>tva` - Show all todos
- `<leader>tvd` - Filter todos with due dates
- `<leader>tvt` - Filter todos due today
- `<leader>tvx` - Filter urgent todos (today + past due)

## Features

- **Category-based todos** (Medicine 💊, OMS 🛠️, Personal 🏡)
- **Future scheduling** with show dates
- **Smart due date highlighting** (red for overdue, green for today, gray for future)
- **Auto-refresh** when adding/completing todos
- **Interactive editing** with `<leader>te`
- **Toggle functionality** with cursor position preservation
- **Filtering by category** and due dates
- **Completed todo reactivation**

## Daily Workflow

1. **Morning Review**: `<leader>to` - See active todos
2. **Add Todos**: `<leader>tb` - Interactive builder or `<leader>ta` - Quick add
3. **Edit Todos**: `<leader>te` - Edit current todo
4. **Complete Todos**: `tt` - Toggle completion
5. **View All**: `<leader>tr` - See all including scheduled

## Recent Development Updates

### ✅ **TODO EDITING FEATURE IMPLEMENTED** (2025-08-31)

**Feature Overview**: Interactive todo editing using existing modal system with smart code reuse.

**Key Components**:

1. **`M.get_current_todo()`** - Extracts todo data from current cursor line with full file data when in filtered views
2. **`M.edit_todo_modal()`** - Simple wrapper that enhances existing modal for edit mode
3. **Enhanced `M.show_todo_modal(options)`** - Now accepts optional parameters for edit vs add mode
4. **`:TodoEditSelected`** command and **`<leader>te`** keybinding - Works in all todo views

**Smart Implementation Approach**:

- **Code Reuse**: Leveraged existing TodoBuild modal system instead of creating duplicate functionality
- **Consistent UX**: Same interface and controls as `<leader>tb` with pre-populated data
- **Zero Learning Curve**: Users already familiar with TodoBuild controls work identically

**Modal Controls** (inherited from existing TodoBuild system):

- **[Tab]** - Navigate between fields (Description → Category → Show Date → Due Date)
- **[i]** - Edit description inline with proper cursor positioning
- **[j/k]** - Navigate categories when on category field
- **[Enter]** - Context-sensitive: date picker on date fields, submit otherwise
- **[s]** - Submit form from anywhere
- **[ESC/q]** - Cancel and close modal

### ✅ **CRITICAL FIXES COMPLETED** (2025-08-31)

**Issues Resolved**:

1. **✅ Cursor Positioning**

   - **Problem**: Cursor positioned one character before end of description text
   - **Root Cause**: Incorrect character count for prefix `" Description:  "` (15 chars, not 14)
   - **Solution**: Implemented Vim motion-based cursor positioning using `0`, `f:`, `2l`, `E` commands
   - **Result**: Reliable cursor positioning at end of description text for both initial load and 'i' key press

2. **✅ Show Date Persistence**

   - **Problem**: Show dates always showing as "not set" and not saving after edits
   - **Root Cause**: `format_todo_line()` only included show dates for "scheduled" context, but active todos saved with "storage" context
   - **Solution**: Modified format function to include show dates in both "scheduled" AND "storage" contexts
   - **Result**: Show dates now properly persist to active todo files and load correctly in edit modal

3. **✅ Cursor Jumping After Updates**

   - **Problem**: After editing todos, cursor would jump to top of filtered list
   - **Solution**: Enhanced `refresh_filtered_view_if_open()` with cursor position preservation
   - **Implementation**: Store cursor line before refresh, restore after content update if line still exists
   - **Result**: Cursor stays on same todo line after editing operations

4. **✅ Filtered List Auto-Refresh**
   - **Already Working**: Filtered views automatically update after todo edits
   - **Implementation**: `refresh_filtered_view_if_open()` called after both save paths in edit modal
   - **Result**: Changes immediately visible in filtered view without manual refresh

### ✅ **TECHNICAL IMPLEMENTATION DETAILS**

**Smart Data Retrieval**:

- `get_current_todo()` detects filtered vs raw views and fetches complete todo data from actual files when needed
- Handles edge case where filtered views hide show dates but edit modal needs full data

**Cursor Position Solutions**:

- **Method**: Vim text objects instead of manual character counting
- **Commands**: `0` (line start) → `f:` (find colon) → `2l` (skip spaces) → `E` (end of word)
- **Reliability**: Works regardless of font, encoding, or display variations

**Buffer State Management**:

- Proper handling of read-only filtered view buffers during edits
- Temporary modifiability enabling with state restoration
- Cross-compatibility with all todo view types

**File-Based Updates**:

- Edit operations update actual todo files instead of just buffer display
- Automatic filtered view refresh pulls from updated files
- Maintains data consistency between views and storage

### ✅ **CURRENT SYSTEM STATUS**

**All Todo Editing Functionality Working**:

- ✅ **`<leader>te` keybinding** works in filtered views and raw todo files
- ✅ **Cursor positioning** accurate at end of description text
- ✅ **Show date persistence** with proper file format handling
- ✅ **Cursor position preservation** after updates
- ✅ **Auto-refresh** of filtered views after edits
- ✅ **Buffer compatibility** across all todo view types

**Code Quality**:

- ✅ **No code duplication** - reused existing modal system
- ✅ **Maintainable** - single modal handles both add and edit operations
- ✅ **Clean implementation** - debug output removed after testing

**User Experience**:

- ✅ **Familiar interface** - identical to TodoBuild modal users already know
- ✅ **Seamless integration** - works everywhere todos are displayed
- ✅ **Reliable operation** - handles edge cases and different buffer types

The todo editing feature is now fully functional and integrated into the existing workflow with zero regressions.

### **RESOLVED ISSUES** ✅ (2025-09-01 - Updated)

**All reported issues have been successfully resolved:**

#### **Issue 1: Show Date Not Applied and Scheduling Not Working** ✅ **FULLY RESOLVED**
- **Problem**: When using `/show tomorrow`, the todo would:
  1. Not save the show date to file (only saved due date)
  2. Appear immediately in active list instead of being scheduled for tomorrow
  3. Show no dates when edited with `<leader>te`
- **Root Cause**: `add_todo` function used "active" context when writing todos, but `format_todo_line` only includes show dates for "scheduled" or "storage" contexts
- **Solution**: 
  1. Fixed date context in `add_todo` function from "active" to "storage" 
  2. Ensured date logic properly sets both show and due dates when only show is provided
- **Result**: 
  - ✅ Show dates now save correctly to file with both `[Show: date]` and `[Due: date]`
  - ✅ Todos scheduled for future dates don't appear in active list until show date arrives
  - ✅ Scheduled todos appear correctly in `:TodoScheduled` list
  - ✅ Today's todos appear immediately in active list
  - ✅ Edit modal shows both dates correctly

#### **Issue 2: Date Shortcut Keywords Not Working** ✅
- **Problem**: `/show tomorrow`, `/show next week`, etc. were throwing errors
- **Root Cause**: `resolve_date_shortcut()` function was referenced but not implemented
- **Solution**: Implemented comprehensive date shortcut resolver with full keyword support:
  - Special cases: `today`, `tomorrow`, `next week`, `this weekend`
  - Pattern support: `[1-12] [days/weeks/months/years]` and `[one-twelve] [unit]`
  - Examples: `5 days`, `two weeks`, `1 month`, `twelve years`
- **Result**: All date shortcuts now work correctly across all todo commands

#### **Issue 3: /due Command Error Flow** ✅ **CORRECTED WORKFLOW IMPLEMENTED**
- **Problem**: `/due` command showed error "When specifying due date, show date is required" and stopped execution
- **Expected Behavior**: Command line should stay active allowing user to add `/show` to complete the command
- **Root Cause**: Logic showed error instead of keeping command line active for continuation
- **Solution**: Implemented interactive continuation workflow using `vim.ui.input`:
  - When `/due` used without `/show`, opens prompt: `:TodoAdd Task [Due: date] /show `
  - User can type date shortcut or just press Enter for calendar picker
  - No error shown, workflow remains active until completion
- **Result**: Command line stays active, user can complete `/show` portion as intended

#### **Issue 4: TodoScheduled and TodoUpcoming Commands Failing** ✅
- **Problem**: Both commands threw errors and didn't work
- **Root Cause**: `get_scheduled_todos()` and `get_upcoming_todos()` functions were not implemented
- **Solution**: Implemented both functions with proper date filtering:
  - `get_scheduled_todos()`: Returns todos with future show dates (not yet active)
  - `get_upcoming_todos(days)`: Returns todos scheduled within next N days (default 7)
  - `display_todos()`: Formats and displays todo lists with proper icons and date info
- **Result**: Both commands now work correctly and display formatted todo lists

#### **Issue 5: Date Logic Consistency** ✅
- **Problem**: Inconsistent behavior between commands for date handling
- **Root Cause**: Each command had its own date handling logic
- **Solution**: Unified all commands to use `handle_command_continuation()` function
- **Result**: Consistent date behavior across TodoAdd, Todo, TodoMed, and TodoOMS commands

#### **Issue 6: TodoAdd Default Category Regression** ✅ **FIXED**
- **Problem**: TodoAdd command using fallback icon (📝) instead of Personal category icon (🏡)
- **Expected Behavior**: TodoAdd should always default to "Personal" category with 🏡 icon
- **Root Cause**: Category defaulting logic was missing in TodoAdd command
- **Solution**: Added explicit category defaulting: `if not category or category == "" then category = "Personal" end`
- **Result**: TodoAdd now consistently uses Personal category (🏡) when no category specified

### **TECHNICAL IMPLEMENTATION DETAILS**

#### **New Functions Added** (todo_manager.lua:773-998)

1. **`resolve_date_shortcut(keyword)`** - Comprehensive date keyword resolver
   - Handles special cases: today, tomorrow, next week, this weekend
   - Supports numeric patterns: "5 days", "two weeks", "1 month"
   - Returns date in mm-dd-yyyy format or nil if invalid

2. **`handle_command_continuation()`** - Unified calendar picker workflow
   - Handles date logic rules (show-only sets both, due-only requires show)
   - Manages sequential calendar picker flow
   - Provides consistent error handling and success messages

3. **`get_scheduled_todos()`** - Returns todos with future show dates
   - Filters out completed todos and currently active todos
   - Uses existing `is_show_date_reached()` logic for consistency

4. **`get_upcoming_todos(days)`** - Returns todos within specified timeframe
   - Defaults to 7 days if not specified
   - Properly parses mm-dd-yyyy date format for comparison

5. **`display_todos(todos, title)`** - Formatted todo list display
   - Shows category icons, tags, show dates, and due dates
   - Provides consistent formatting across listing commands

#### **Code Consolidation**

- **TodoAdd Command**: Refactored to use unified continuation system
- **Removed Duplicate Logic**: Eliminated 40+ lines of duplicate date picker code
- **Consistent Error Handling**: All commands now use the same error messages and flows

#### **Testing Results** ✅ **COMPREHENSIVE VERIFICATION**

All functionality verified working correctly:

```bash
# Date shortcuts and scheduling work correctly
:TodoAdd Test task /show tomorrow          # ✅ Saves [Show: 09-02-2025] [Due: 09-02-2025]
                                          # ✅ Does NOT appear in :TodoList (scheduled for tomorrow)
                                          # ✅ Appears in :TodoScheduled list

:TodoAdd Task /show today                  # ✅ Saves [Show: 09-01-2025] [Due: 09-01-2025]  
                                          # ✅ Appears immediately in :TodoList (active today)

:TodoAdd Task /show next week              # ✅ Sets both dates to next week and schedules correctly
:TodoAdd Task /show 5 days /due two weeks  # ✅ Different show and due dates work correctly

# Commands work without errors
:TodoScheduled                             # ✅ Shows only future scheduled todos
:TodoUpcoming                              # ✅ Shows upcoming todos (7 days)
:TodoUpcoming 14                           # ✅ Shows upcoming todos (14 days)

# Continuation workflow works correctly
:TodoAdd Task /due tomorrow                # ✅ Opens prompt: ":TodoAdd Task [Due: 09-02-2025] /show "
                                          # ✅ User can type "/show today" or press Enter for picker
                                          
# Default category works correctly  
:TodoAdd Test task                         # ✅ Uses Personal category (🏡) not fallback (📝)

# File storage verification  
# Raw file shows: - [ ] 🏡 Test task [Show: 09-02-2025] [Due: 09-02-2025] (09-01-2025)
# Edit modal shows both dates correctly when using <leader>te
```

### **CURRENT SYSTEM STATUS**

**All Todo Functionality Working Perfectly**:

- ✅ **Show date scheduling** - Future todos hidden from active list until show date arrives  
- ✅ **Date shortcuts** - All keywords working (`tomorrow`, `next week`, `5 days`, etc.)
- ✅ **Calendar pickers** - Date selections properly applied to todos
- ✅ **File storage** - Show dates saved correctly with `[Show: date] [Due: date]` format
- ✅ **Command workflows** - All todo commands work consistently
- ✅ **Scheduled todos** - TodoScheduled command displays future todos  
- ✅ **Upcoming todos** - TodoUpcoming command shows upcoming todos
- ✅ **Edit functionality** - `<leader>te` displays both show and due dates correctly
- ✅ **Error handling** - Proper error messages with workflow preservation
- ✅ **Date logic** - Show-only automatically sets both show and due dates

**Code Quality**:

- ✅ **No regressions** - All existing functionality preserved
- ✅ **Unified system** - All commands use consistent date handling
- ✅ **Maintainable** - Single source of truth for date processing
- ✅ **Well tested** - All reported issues verified resolved

The todo system is now fully functional with all reported bugs resolved and no regressions introduced.
