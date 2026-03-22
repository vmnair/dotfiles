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
| `<leader>tl` | | Clear category filter (show all) |
| `<leader>to` | `:TodoOpen` | Open active todos (shows filter status in message) |
| `<leader>tb` | | Interactive todo builder with calendar |
| `<leader>tr` | | Open raw todos file (includes scheduled) |
| `<leader>tc` | | Open completed todos file |
| `<leader>tf` | `:TodoFilter` | Category filter menu (centered, auto-sized dialog) |

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
- **Search**: `grep -r "todo_id: <id>" ~/notebook/` (no timeout — macOS lacks GNU `timeout`)
- **Note creation**: `zk new <folder> --title "..." --print-path`
- **Frontmatter**: YAML with `todo_id`, category, tags, dates
- **Template**: Frontmatter → Title → Metadata → `## Original Todo` → `## Notes`
- **Existing notes**: Opens at end of Notes section, adds new date stamp if different day
- **Cursor positioning**: Always immediately below the date line; same day revisits add one blank line
- **Orphan detection**: Warns user if 󰈙 indicator exists but no linked note file is found
- **Auto-save**: On InsertLeave or BufLeave
- **Return navigation**: `:w` from note saves and returns to todo list at original cursor position
- **Note indicator**: 󰈙 (nf-md-file_document) with yellow highlight (#ffd700)
- **Folder picker**: `fzf-lua.fzf_exec` with clean single-frame UI, `todo` as default folder
- **Requires**: `zk` CLI (`brew install zk` on macOS)

## Testing

**Run all tests** (from `neovim/nvim/`):
```bash
./tests/run_tests.sh
# or directly:
nvim --headless -l tests/todo_manager_spec.lua
```

**Run a specific test file**:
```bash
./tests/run_tests.sh tests/todo_manager_spec.lua
```

**Test file**: `neovim/nvim/tests/todo_manager_spec.lua`
- Standalone Lua tests using `nvim --headless -l` (no plenary/busted dependency)
- Mini assertion framework built into the file
- Tests 8 pure functions: `parse_todo_line`, `format_todo_line`, `validate_category`, `is_past_due`, `is_due_today`, `is_show_date_reached`, `resolve_date_shortcut`, `generate_todo_id`
- Round-trip tests (parse → format) catch subtle regressions

**Adding new tests**: Add `test("name", function() ... end)` inside an existing or new `describe()` block. Use `assert_eq`, `assert_true`, `assert_false`, `assert_nil`, `assert_not_nil`, `assert_table_len`.

**Private function access**: `M._test` exposes `generate_todo_id` and `is_show_date_reached` for testing.
