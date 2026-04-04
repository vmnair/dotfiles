# Todo Manager Development Documentation

Neovim task management system with category-based todos, future scheduling, interactive editing, and ZK integration.

## Plugin Structure

Local plugin at `neovim/nvim/dev-plugins/todo-manager.nvim/`:

```
lua/todo-manager/
├── init.lua          # Config, public API re-exports
├── parser.lua        # parse_todo_line, format_todo_line
├── dates.lua         # Date logic (is_past_due, resolve_date_shortcut, etc.)
├── categories.lua    # Category validation, filter state
├── storage.lua       # File I/O, todo retrieval (get_active, add_todo, etc.)
├── ui.lua            # Filtered view, syntax, keybindings, toggle
├── calendar.lua      # Date picker floating window
├── modal.lua         # Todo create/edit dialog
├── continuation.lua  # Command continuation workflow
├── commands.lua      # All user commands and keybindings
└── zk.lua            # ZK note integration, todo ID generation
```

**Loading**: `rtp:prepend` in `init.lua`, commands loaded via `require("todo-manager.commands")`.

**Inter-module communication**: Lazy `require()` inside functions to avoid circular dependencies.

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

**Storage format**: `- [ ] icon Description [Show: date] [Due: date] #tag (added_date) 󰈙`

**Parse order in `parse_todo_line()`**: show_date → due_date → note icon (󰈙) → added_date → tags → category icon → description

## Configuration

Defined in `init.lua` `M.config`:
- **Todo dir**: `~/Library/CloudStorage/Dropbox/notebook/todo/`
- **Active file**: `active-todos.md`
- **Completed file**: `completed-todos.md`
- **Categories**: Medicine (󰿷), OMS (󰇄), Personal ()

## Commands & Keybindings

### Global
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>ta` | `:TodoAdd` | Quick add todo |
| `<leader>tl` | | Clear category filter (show all) |
| `<leader>to` | `:TodoOpen` | Open active todos |
| `<leader>tb` | `:TodoBuild` | Interactive todo builder modal |
| `<leader>tr` | `:TodoOpenRaw` | Open raw todos file (includes scheduled) |
| `<leader>tc` | `:TodoOpenCompleted` | Open completed todos file |
| `<leader>tf` | `:TodoFilter` | Category filter menu |
| `<leader>ts` | `:TodoStats` | Show todo statistics |
| `<leader>th` | `:TodoHelp` | Show help window |

### In todo files
| Key | Description |
|-----|-------------|
| `tt` | Toggle completion |
| `<leader>te` | Edit current todo (pre-populated modal) |
| `<leader>tz` | Create or open zk note from todo |
| `<leader>td` | Update due date with calendar picker |
| `<leader>tc` | Open completed todos file |

### Quick add commands
`:Todo`, `:TodoMed`, `:TodoOMS` - Add with pre-set category

## ZK Integration

Located in `zk.lua`:
- **Todo ID**: Hash of `description|category|added_date` → `todo_123456`
- **Search**: `grep -r -F -l` with table args (no shell injection)
- **Note creation**: `zk new` with table args
- **Path validation**: Canonicalized against `notebook_dir`
- **Frontmatter**: YAML with `todo_id`, category, tags, dates
- **Note indicator**: 󰈙 appended to todo line when note is linked
- **Orphan detection**: Warns if 󰈙 exists but no linked note found
- **Auto-save**: On InsertLeave/BufLeave, returns to todo list on save
- **Folder picker**: `fzf-lua.fzf_exec`, `todo` as default folder
- **Requires**: `zk` CLI (`brew install zk` on macOS)

## Testing

**Run all tests** (from `neovim/nvim/dev-plugins/todo-manager.nvim/`):
```bash
./tests/run_tests.sh
```

**Run a specific test file**:
```bash
./tests/run_tests.sh tests/parser_spec.lua
```

**Test files** (65 tests total):
| File | Tests | Covers |
|------|-------|--------|
| `parser_spec.lua` | 19 | parse_todo_line, format_todo_line, round-trips |
| `dates_spec.lua` | 28 | is_past_due, is_due_today, is_show_date_reached, resolve_date_shortcut |
| `categories_spec.lua` | 12 | validate_category, update_static_categories, filter state |
| `storage_spec.lua` | 6 | generate_todo_id |

**Framework**: Standalone Lua tests (`nvim --headless -l`), no external dependencies. Shared helpers in `tests/helpers.lua` (vim stubs, assertions).

**Adding new tests**: Add `test("name", function() ... end)` inside a `describe()` block. Use `assert_eq`, `assert_true`, `assert_false`, `assert_nil`, `assert_not_nil`, `assert_table_len`.

**Private function access**: `_test` tables on `zk.lua` (generate_todo_id) and `continuation.lua` (parse_continuation_input, format_todo_success_message).
