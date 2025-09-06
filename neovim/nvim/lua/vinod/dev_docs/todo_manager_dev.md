# Todo Manager Development Documentation

## System Overview

Comprehensive task management system for Neovim with category-based todos, future scheduling, and interactive editing.

## ✅ CURRENT STATUS (2025-09-06)
**ZK Integration**: FULLY FUNCTIONAL - Note creation and duplicate detection working correctly.
**Status**: All features operational, no known issues.

**Core Files**:
- **Main Logic**: `todo_manager.lua` - Core functionality
- **Commands**: `config/todo_commands.lua` - User commands and keybindings

## Core Data Structure

```lua
{
    completed = false,           -- boolean
    description = "Task text",   -- string
    category = "Personal",       -- string (Medicine|OMS|Personal)
    tags = {"urgent", "health"}, -- array of strings
    due_date = "09-30-2025",    -- mm-dd-yyyy string
    show_date = "09-28-2025",   -- mm-dd-yyyy string
    added_date = "09-30-2025",  -- mm-dd-yyyy string
    completion_date = "",        -- mm-dd-yyyy string (when completed)
}
```

**File Format**:
```markdown
- [ ] 💊 Take morning medication [Show: 09-30-2025] [Due: 09-30-2025] #urgent #health
```

## Configuration

**File Locations**:
- **Active**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo/active-todos.md`
- **Completed**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo/completed-todos.md`

**Categories**: Medicine 💊, OMS 🛠️, Personal 🏡

## Key Commands & Workflows

### Essential Commands
- `:TodoAdd <desc> /show /due` - Add todo with calendar pickers
- `:TodoMed`, `:TodoOMS`, `:Todo` - Quick category additions
- `:TodoList` - List currently active (visible) todos
- `:TodoEditSelected` - Edit todo on current line

### Global Keybindings
- `<leader>ta` - Quick add todo
- `<leader>tl` - List active todos
- `<leader>to` - **Main daily workflow** - Open filtered view of active todos
- `<leader>tb` - Interactive todo builder with calendar picker
- `<leader>tr` - Open raw todos file (includes scheduled todos)
- `<leader>tc` - Open completed todos file

### File-Specific Keybindings (in todo files)
- `tt` - Toggle completion
- `<leader>te` - Edit current todo
- `<leader>tz` - Create or open zk note from todo (smart detection)
- `<leader>tc` - Open completed todos file
- `<leader>td` - Update due date with calendar picker

### Category Filtering
- `:TodoFilter [Category|Clear]` - Apply/clear category filters
- `<leader>tf` - Interactive filter menu with category selection

## Key Features

### **Future Scheduling**
- **Show Dates**: Control when todos become visible
- **Due Dates**: Highlight urgency (red=overdue, green=today, gray=future)
- **Smart Logic**: `/show` only sets both dates, `/due` requires `/show`

### **Interactive Editing**
- **TodoBuilder** (`<leader>tb`): Modal with description, category, dates
- **Edit Mode** (`<leader>te`): Pre-populated modal for existing todos
- **Calendar Integration**: Date picker for all date fields

### **Category Filtering** 
- **In-place Filtering**: Filter current view without new buffers
- **Smart Integration**: TodoBuilder pre-selects filtered category
- **Menu Interface**: `<leader>tf` with vim.ui.select
- **Buffer Names**: Update to reflect filter state

### **Visual Highlighting**
- **Syntax**: Hybrid markdown + todo overlays for best visual appearance
- **Keywords**: `#tags` in blue, icons in yellow
- **Checkboxes**: Proper markdown checkbox rendering
- **Due Dates**: Color-coded by urgency

### **ZK Integration (Zettelkasten Notes)** ✅
- **Smart Detection**: `<leader>tz` checks for existing notes with matching titles
- **Existing Notes**: Opens found note for editing and continuation
- **New Notes**: Creates structured note with todo metadata and template
- **Note Template**: Includes category, tags, dates, and original todo reference
- **Optional Completion**: Prompts to mark todo completed after note interaction
- **Requirements**: zk command-line tool must be installed (`brew install zk`)

## Daily Workflow

1. **Morning**: `<leader>to` - See active todos
2. **Add**: `<leader>tb` - Interactive builder
3. **Filter**: `<leader>tf` - Focus on specific category
4. **Edit**: `<leader>te` - Modify existing todos
5. **Notes**: `<leader>tz` - Create/open zk note from todo
6. **Complete**: `tt` - Toggle completion
7. **Review**: `<leader>tr` - All todos including scheduled

## Recent Major Updates

### **Syntax Highlighting System** ✅
- **Hybrid Approach**: Markdown base + todo overlays
- **Immediate Highlighting**: Keywords appear on first load
- **Proper Checkboxes**: Beautiful markdown checkbox rendering
- **Fixed `$text$`**: No more teal math syntax coloring

### **Category Filtering System** ✅
- **In-Place Filtering**: No scratch buffers, updates current view
- **Smart Integration**: TodoBuilder respects active filter
- **Menu Interface**: Interactive category selection
- **Dynamic Categories**: Add/remove categories safely

### **Interactive Editing** ✅
- **TodoBuilder Fix**: Description editing works reliably
- **Cursor Positioning**: Proper positioning in all contexts
- **Filter Persistence**: Edits maintain active category filters
- **Auto-refresh**: Changes appear immediately in filtered views

### **Command Workflows** ✅
- **Date Logic**: Show-only sets both, due-only requires show
- **Continuation**: Interactive prompts for incomplete commands
- **Keyboard Shortcuts**: All date shortcuts working (`tomorrow`, `next week`, etc.)
- **Error Handling**: Proper validation with helpful messages

### **ZK Integration System** ✅ (Complete)
- **Basic Functionality**: `<leader>tz` creates notes from todos ✅
- **Duplicate Detection**: Finds and opens existing notes by todo_id ✅
- **Keybinding**: `<leader>tz` for ZK note creation/opening ✅  
- **Frontmatter System**: Notes include `todo_id` for permanent linking ✅
- **Template Structure**: H1 heading, metadata, cursor positioning ✅
- **Error Handling**: zk installation checks, graceful failures ✅

#### **Implementation Details**
- **Search Method**: Uses `grep -r "todo_id: <id>" ~/notebook/` with 5s timeout
- **Path Resolution**: Converts relative paths to absolute for vim editing
- **Duplicate Prevention**: Opens existing notes instead of creating duplicates
- **User Workflow**: Optional todo completion prompt after opening existing notes
- **Fallback**: Creates new note if no existing note found

#### **Technical Notes**
- **Todo ID Generation**: Uses `description + category + added_date` hash for consistent IDs
- **Frontmatter Format**: YAML with `todo_id: todo_123456`
- **Search Strategy**: Searches frontmatter metadata (zk --match doesn't search YAML frontmatter)
- **Notebook Location**: Searches in `~/notebook/` directory (actual zk repository location)
- **Safety**: 5-second timeout prevents system hanging

#### **Troubleshooting Issues Resolved**
- **Issue**: zk --match parameter doesn't search YAML frontmatter
- **Solution**: Use grep to search frontmatter directly instead of zk native search
- **Issue**: Wrong search path (~/.zk/ vs ~/notebook/)
- **Solution**: Updated to use correct notebook directory where zk stores notes
- **Issue**: Duplicate note creation on repeated `<leader>tz` invocation
- **Solution**: Proper frontmatter search now detects existing notes and opens them

## Technical Notes

### **Syntax System**
- **Filetype**: `markdown` for proper checkbox rendering
- **Overlays**: Todo-specific patterns with `containedin=ALL`
- **Timing**: Multiple application strategies for reliability
- **Emoji Handling**: Separate patterns for each icon

### **Filter Architecture**
- **State**: `M.current_filter` tracks active category
- **Buffer Names**: Dynamic updating to reflect filter
- **Integration**: All operations respect filter context
- **Persistence**: Filter maintained across todo operations

### **Date Handling**
- **Shortcuts**: `today`, `tomorrow`, `next week`, `5 days`, etc.
- **Validation**: Proper mm-dd-yyyy format checking
- **Logic**: Smart defaults and continuation workflows
- **Calendar**: Interactive date picker integration

System is feature-complete with all major functionality working reliably. ZK integration now fully operational with duplicate detection and existing note opening capabilities.