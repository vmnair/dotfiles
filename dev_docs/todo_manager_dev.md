# Todo Manager Development Documentation

Neovim task management system with category-based todos, future scheduling, interactive editing, and ZK integration.

**Core Files**:
- `todo_manager.lua` - Core functionality
- `config/todo_commands.lua` - User commands and keybindings

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

**Storage format**: `- [ ] 💊 Take medicine [Show: date] [Due: date] #tag (added_date) 󰈙`

**Parse order in `parse_todo_line()`**: show_date → due_date → note icon (󰈙) → added_date → tags → category icon → description

## Configuration

**File Locations**:
- **Active**: `~/Library/CloudStorage/Dropbox/notebook/todo/active-todos.md`
- **Completed**: `~/Library/CloudStorage/Dropbox/notebook/todo/completed-todos.md`

**Categories**: Medicine 💊, OMS 🛠️, Personal 🏡

## Commands & Keybindings

### Global
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>ta` | `:TodoAdd` | Quick add todo |
| `<leader>tl` | `:TodoList` | List active todos |
| `<leader>to` | | Open filtered view of active todos |
| `<leader>tb` | | Interactive todo builder with calendar |
| `<leader>tr` | | Open raw todos file (includes scheduled) |
| `<leader>tc` | | Open completed todos file |
| `<leader>tf` | `:TodoFilter` | Category filter menu |

### In todo files
| Key | Description |
|-----|-------------|
| `tt` | Toggle completion |
| `<leader>te` | Edit current todo (pre-populated modal) |
| `<leader>tz` | Create or open zk note from todo |
| `<leader>td` | Update due date with calendar picker |

### Quick add commands
`:TodoMed`, `:TodoOMS`, `:Todo` - Add with pre-set category

## ZK Integration Details

- **Todo ID**: Hash of `description + category + added_date` → `todo_123456`
- **Search**: `grep -r "todo_id: <id>" ~/notebook/` with 5s timeout
- **Note creation**: `zk new <folder> --title "..." --print-path`
- **Frontmatter**: YAML with `todo_id`, category, tags, dates
- **Template**: Frontmatter → Title → Metadata → `## Original Todo` → `## Notes`
- **Existing notes**: Opens at end of Notes section, adds new date stamp if needed
- **Auto-save**: On InsertLeave or BufLeave
- **Return navigation**: Returns to original todo line after saving/exiting note
- **Note indicator**: 󰈙 (nf-md-file_document) with yellow highlight (#ffd700)
- **Folder picker**: `vim.ui.select` over `~/notebook` subdirs, `todo` as default
- **Requires**: `zk` CLI (`brew install zk` on macOS)
