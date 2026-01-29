# Todo Manager Development Documentation

## System Overview

Comprehensive task management system for Neovim with category-based todos, future scheduling, interactive editing, and ZK integration.

## ✅ CURRENT STATUS (2026-01-28)

**Core Functionality**: All major features working correctly.
**ZK Integration**: Full functionality with folder selection for note placement.
**Return Navigation**: Fixed - returns to original todo line after ZK note editing.

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
- `<leader>tz` - Create or open zk note from todo
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
- **Folder Selection**: Shows picker with all `~/notebook` subfolders, `todo` as default
- **New Notes**: Creates structured note with todo metadata and template
- **Note Template**: Includes category, tags, dates, and original todo reference
- **Return Navigation**: Returns to original todo line after saving/exiting ZK note
- **Note Link Icon**: 󰈙 (nf-md-file_document) in yellow indicates linked note
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

### **ZK Integration System** ✅ (Complete)
- **Basic Functionality**: `<leader>tz` creates/opens notes from todos ✅
- **Duplicate Detection**: Finds and opens existing notes by todo_id ✅
- **Folder Selection**: Picker shows all notebook folders, `todo` as default ✅
- **Return Navigation**: Returns to original todo line after note editing ✅
- **Template Structure**: H1 heading, metadata, cursor positioning ✅
- **Error Handling**: zk installation checks, graceful failures ✅

#### **Implementation Details**
- **Folder Discovery**: `get_notebook_folders()` uses `find` to recursively list all directories in `~/notebook`, skipping hidden folders
- **Folder Picker**: Uses `vim.ui.select` with `todo` folder shown first as "(default)"
- **Search Method**: Uses `grep -r "todo_id: <id>" ~/notebook/` with 5s timeout
- **Path Resolution**: Converts relative paths to absolute for vim editing
- **Duplicate Prevention**: Opens existing notes instead of creating duplicates
- **Todo ID Generation**: Uses `description + category + added_date` hash for consistent IDs
- **Frontmatter Format**: YAML with `todo_id: todo_123456`
- **Note Creation**: `zk new <selected_folder> --title "..." --print-path`
- **Note Link Icon**: 󰈙 (nf-md-file_document) with yellow highlight (#ffd700)
- **Template Order**: Frontmatter → Title → Metadata → `## Original Todo` → `## Notes`
- **Notes Section**: Includes date entry (mm/dd/yyyy) for timestamped entries
- **Cursor Positioning**: Places cursor below the date line, ready for notes
- **Existing Notes**: Opens at end of Notes section, adds new date if different from last entry
- **Auto-Save**: Notes automatically save on InsertLeave or BufLeave (no manual :w needed)

System is feature-complete with all major functionality working reliably. ZK integration fully operational with folder selection, duplicate detection, and existing note opening capabilities.