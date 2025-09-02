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

## **NEW FEATURE: IN-PLACE CATEGORY FILTERING** 📋

### **Feature Overview**
In-place category filtering allows users to filter the current todo view by category without opening new scratch buffers. The filtered view integrates with TodoBuilder and provides both menu and command-line interfaces.

### **Core Components**

#### **1. Filter State Management**
- Global filter state tracking current category (Medicine/OMS/Personal/Clear)  
- Filter persistence across todo operations (add, complete, edit)
- Integration with existing refresh mechanisms
- Visual feedback in buffer names and headers

#### **2. User Interfaces**
- **Menu Interface**: `<leader>tf` - Interactive category selection menu
- **Command Interface**: `:TodoFilter [Category]` with validation and error handling
- **Visual Feedback**: Buffer name changes to show active filter status

#### **3. Category Management System**
- **Static Configuration**: Categories stored in `M.config.categories`
- **Dynamic Updates**: New categories automatically available in filter system
- **Validation**: Strict category validation with suggestions for typos
- **Safe Removal**: Category deletion requires completing all active/scheduled todos

### **Filter Commands**

#### **`:TodoFilter` Command Variants**
```bash
:TodoFilter Medicine      # Apply Medicine category filter
:TodoFilter Personal      # Apply Personal category filter  
:TodoFilter OMS          # Apply OMS category filter
:TodoFilter Clear        # Remove filter (show all todos)
:TodoFilter              # Show current filter status or open menu
:TodoFilter Work         # Apply custom category filter (if exists)
:TodoFilter Invalid      # Error + suggestions for valid categories
```

#### **Error Handling & Suggestions**
```bash
:TodoFilter Medicin      # "Did you mean: Medicine?"
:TodoFilter xyz          # "Category 'xyz' not found. Available: Medicine, OMS, Personal"
```

### **Menu Interface (`<leader>tf`)**
Uses `vim.ui.select` for consistent interface with TodoBuilder:
```
Todo Category Filter:
● Clear (23 todos)          ← Currently active (filled circle)
○ Medicine 💊 (5)
○ OMS 🛠️ (8)
○ Personal 🏡 (10) 
○ Work 💼 (0)              ← Empty but available
```

### **Visual Feedback System**

#### **Buffer Names**
- **No Filter**: "Active Todos (Filtered View)"
- **With Filter**: "Active Todos - Medicine Filter"  
- **Empty Filter**: "Active Todos - Medicine Filter (No todos found)"

#### **Buffer Headers**
- **Filtered**: "Showing 5 Medicine todos (18 others hidden)"
- **Empty**: "No todos found in Medicine category - Use :TodoFilter Clear to show all"

### **TodoBuilder Integration**

#### **Category Pre-selection**
- **Filter Active**: TodoBuilder (`<leader>tb`) defaults to filtered category
- **No Filter**: TodoBuilder defaults to "Personal" as usual  
- **User Override**: User can still change category in TodoBuilder if needed

#### **Workflow Example**
```bash
:TodoFilter Medicine     # Apply Medicine filter
<leader>tb              # TodoBuilder opens with Medicine pre-selected
# User creates Medicine todo → appears immediately in filtered view
```

### **Category Management Workflows**

#### **Adding New Categories**
```bash
:TodoAddCategory Work 💼
# → Updates M.config.categories = { "Medicine", "OMS", "Personal", "Work" }
# → :TodoFilter Work becomes valid command
# → <leader>tf menu shows Work option  
# → TodoBuilder includes Work in category selection
```

#### **Category Removal Workflow**  
```bash
:TodoRemoveCategory Work
# Step 1: Check for active/scheduled todos
# → If active/scheduled exist: "Cannot remove 'Work'. Complete 3 active, 2 scheduled todos first."
# → If none exist: Proceed with removal

# Step 2: Handle active filter  
# → If Work filter active + no remaining todos: Auto-clear filter, show all
# → If Work filter active + todos remain: Show error, require manual clear

# Step 3: Preserve completed todos
# → Completed Work todos remain in completed file with Work category
# → Historical data preserved
```

### **Empty Category Handling**
- **Stay Filtered**: Don't auto-clear when category becomes empty
- **Clear Message**: "No todos found in [Category] - Use :TodoFilter Clear or <leader>tf to change"  
- **User Decision**: Let user manually change or clear filter

### **Technical Implementation**

#### **New Functions Added**
```lua
-- Filter State Management
M.current_filter = nil                    -- Global filter state
M.set_category_filter(category)           -- Apply in-place filter
M.clear_category_filter()                 -- Remove filter
M.get_current_filter()                    -- Get active filter state

-- Category Management  
M.validate_category(name)                 -- Check + suggestions
M.update_static_categories(new_category)  -- Add to config
M.remove_category_with_checks(category)   -- Safe removal with validation

-- In-Place Filtering
M.apply_category_filter_to_current_view() -- Update current buffer
M.refresh_filtered_view_with_state()      -- Maintain filter during refresh
M.get_category_todo_counts()              -- For menu display

-- Menu System
M.show_category_filter_menu()             -- Interactive category selection
```

#### **Integration Points**
- **Existing Filters**: Replace `<leader>tvm`, `<leader>tvo`, `<leader>tvp` with in-place filtering
- **Auto-refresh**: Maintain filter state during todo operations
- **TodoBuilder**: Pre-select filtered category when modal opens
- **Buffer Management**: Update buffer names and headers dynamically

### **Error Handling & Edge Cases**

#### **Category Validation**
- Invalid category names with fuzzy matching suggestions
- Case-insensitive matching with proper case correction
- Fallback to filter menu for invalid inputs

#### **Filter State Management**  
- Filter persistence across todo operations (add/complete/edit)
- Multiple buffer handling (each buffer maintains its own filter state)
- Memory cleanup when buffers are closed

#### **Category Lifecycle**
- Safe category addition with conflict detection
- Protected category removal with active todo checks  
- Graceful handling of filter state during category operations

### **Testing Scenarios**

#### **Basic Filtering**
- Apply category filters via command and menu
- Clear filters and verify all todos shown
- Visual feedback verification (buffer names, headers)

#### **TodoBuilder Integration**
- Filter active → TodoBuilder pre-selects category
- Create todo → appears in filtered view immediately
- Change category in TodoBuilder → works normally

#### **Category Management**
- Add new category → appears in filter menu and commands
- Remove category with active todos → proper error handling
- Remove empty category → graceful filter clearing

#### **Edge Cases**
- Invalid category names with suggestion testing
- Empty category filtering behavior
- Multiple buffer filter state independence
- Filter persistence across operations

### **Implementation Status: COMPLETED** ✅

**All Core Features Working:**
- ✅ **TodoFilter Command**: All variants working (Medicine/OMS/Personal/Clear/Invalid)
- ✅ **Filter Menu**: `<leader>tf` with vim.ui.select interface 
- ✅ **TodoBuilder Integration**: Pre-selects filtered category automatically
- ✅ **Category Management**: Add/Remove with safety checks
- ✅ **Validation System**: Typo detection and suggestions
- ✅ **Dynamic Categories**: New categories immediately available in all systems

**Testing Results:**
```bash
# All commands tested and working
:TodoFilter Medicine        # ✓ Filter applied: Medicine
:TodoFilter Clear          # ✓ Filter cleared - showing all todos  
:TodoFilter Invalid        # ✓ Error with suggestions
:TodoFilter Medicin        # ✓ "Did you mean: Medicine?"
:TodoAddCategory Work 💼   # ✓ Category added and available in filter
:TodoRemoveCategory Work   # ✓ Safety checks working correctly
<leader>tf                 # ✓ vim.ui.select menu with counts and icons
<leader>tb                 # ✅ Pre-selects filtered category
```

### **Key Implementation Details**

#### **Filter State Management** (todo_manager.lua:994-1238)
- `M.current_filter` - Global state variable (nil = show all)
- `M.set_category_filter(category)` - Apply filter with view refresh
- `M.clear_category_filter()` - Remove filter and refresh
- `M.get_current_filter()` - Get active filter state

#### **Category Validation** (todo_manager.lua:1022-1056)
- Exact match with case-insensitive search
- Fuzzy matching for suggestions ("Medicin" → "Medicine?")
- Available categories listing on invalid input
- Fallback to filter menu for correction

#### **TodoBuilder Integration** (todo_manager.lua:1880-1883)
```lua
-- Pre-select filtered category or default to Personal
local default_category = M.current_filter or "Personal"
local form_data = {
  category = options.category or default_category,
  -- ... other fields
}
```

#### **Menu Interface** (todo_commands.lua:1052-1102)
- Uses `vim.ui.select` for consistency with TodoBuilder
- Shows active filter with filled circles (●/○)
- Displays category icons and todo counts
- Clean cancellation handling

#### **Commands Added**
- `:TodoFilter [Category|Clear]` - Apply/clear filters with validation
- `:TodoRemoveCategory <name>` - Safe category removal with checks
- `<leader>tf` - Interactive filter menu

### **Benefits**
- **Intuitive Workflow**: No context switching between scratch buffers
- **Smart Integration**: TodoBuilder automatically respects filtering context  
- **Comprehensive Interface**: Both menu and command-line access with consistent vim.ui.select
- **Safe Operations**: Protected category management with validation
- **Visual Clarity**: Clear feedback on filter state and todo counts
- **Dynamic System**: Categories added/removed propagate to all features instantly
