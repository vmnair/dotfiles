# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for various development tools and environments. The repository supports both Linux (Debian-based) and macOS setups.

## Development Commands

### Build and Development

- **Go projects**: Use the Makefile for Go-based development
  - `make build` - Format, vet, and build Go code
  - `make fmt` - Format Go code
  - `make vet` - Run Go vet checks
  - `make clean` - Remove compiled files

### Neovim Development

- **Plugin management**: Uses lazy.nvim for plugin management
- **Custom plugin development**: Local plugins are stored in `neovim/nvim/dev-plugins/`
- **Configuration reload**: Restart Neovim or use `:Lazy reload` after config changes
- **Manual Neovim installation**: Use `neovim/install_neovim.sh` for building from source on Linux

## Architecture and Structure

### Neovim Configuration

- **Entry point**: `neovim/nvim/init.lua`
- **Configuration modules**: Located in `neovim/nvim/lua/vinod/config/`

  - `lazy.lua` - Plugin manager setup (sets mapleader to `,` and localleader to `;`)
  - `options.lua` - Vim options and settings
  - `mappings.lua` - Key mappings (loaded after plugins)
  - `autocmds.lua` - Autocommands
  - `aliases.lua` - Command aliases
  - `util.lua` - Utility functions

- **Plugin configurations**: Located in `neovim/nvim/lua/vinod/plugins/`

  - Each plugin has its own configuration file
  - DAP (Debug Adapter Protocol) configs in `dap/` subdirectory
  - LuaSnip snippets in `luasnip/` subdirectory

- **Development plugins**: `neovim/nvim/dev-plugins/readwise.nvim/` - Custom plugin for Readwise integration

### Todo Manager System

- **Main file**: `neovim/nvim/lua/vinod/todo_manager.lua` - Core todo management functionality
- **Commands**: `neovim/nvim/lua/vinod/config/todo_commands.lua` - User commands and keybindings
- **Data location**: `/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/todo/`
  - `active-todos.md` - Current active todos (includes both visible and scheduled)
  - `completed-todos.md` - Completed todos archive

#### **Future Reminders Feature** (Added 2025-01-27)
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

#### **Key Commands & Keybindings** (Updated 2025-07-29):

**Essential Commands**:
- `:TodoAdd <desc> | Show: mm-dd-yyyy | Due: mm-dd-yyyy` - Full syntax with show/due dates
- `:TodoAdd <desc> /show /due` - Sequential calendar pickers  
- `:TodoMed`, `:TodoOMS`, `:Todo` - Quick category additions with show/due date support
- `:TodoList` - List currently active (visible) todos
- `:TodoScheduled` - List all scheduled (future) todos with show dates
- `:TodoUpcoming [days]` - List todos scheduled for next N days (default 7)
- `:TodoStats` - Show comprehensive todo statistics

**Global Keybindings (work anywhere)** - **NEW CONSISTENT SCHEME**:
- `<leader>ta` - Quick add todo (opens :TodoAdd prompt)
- `<leader>tl` - List active todos  
- `<leader>to` - Open filtered view of active todos (main daily workflow)
- `<leader>ts` - Show todo statistics
- `<leader>tb` - Interactive todo builder with calendar picker
- `<leader>th` - Show todo help window
- `<leader>tr` - Open raw todos file (includes scheduled todos)
- `<leader>tcc` - Open completed todos file

**File-Specific Keybindings (in todo files only)**:
- `tt` - Toggle completion in todo files (works in filtered view and raw files)
- `<leader>tc` - Create zk note from todo
- `<leader>td` - Update due date with calendar picker

**View/Filter Keybindings (in todo files only)**:
- `<leader>tvm` - Filter Medicine todos
- `<leader>tvo` - Filter OMS todos  
- `<leader>tvp` - Filter Personal todos
- `<leader>tva` - Show all todos (remove filters)
- `<leader>tvd` - Filter todos with due dates
- `<leader>tvt` - Filter todos due today
- `<leader>tvx` - Filter urgent todos (today + past due)
- `<leader>tvq` - Close filter window

#### **Features**:
- Category-based todos (Medicine 💊, OMS 🛠️, Personal 🏡)
- Future reminders: Schedule todos to appear on specific dates
- Smart due date highlighting (red for overdue, green for today, gray for future)
- Auto-refresh when adding/completing todos (filtered view updates immediately)
- Filtering by category, due dates, and show dates
- Syntax highlighting: Show dates in cyan/teal, due dates with color-coded urgency
- Index-based operations work correctly with filtered views
- Toggle functionality: `tt` works in both filtered and raw views with full sync
- Completed todo reactivation: Use `tt` in completed todos file to bring back to active

#### **Daily Workflow** (Updated with new keybindings):
1. **Morning Review**: `<leader>to` - See only current active todos (filtered view)
2. **Add New Todos**: `<leader>ta` or `:Todo description /show mm-dd-yyyy /due mm-dd-yyyy` 
3. **Complete Todos**: Press `tt` on any todo line (works in filtered view)
4. **Check Upcoming**: `:TodoScheduled` or `:TodoUpcoming [days]`
5. **Reactivate Completed**: `<leader>tcc` then `tt` on completed todo
6. **View All (Admin)**: `<leader>tr` - See all todos including scheduled
7. **Quick Help**: `<leader>th` - Show comprehensive help window

### Shell and Terminal Configuration

- **Zsh**: Separate configs for Linux (`zshrc_linux`) and macOS (`zshrc_mac`)
- **Tmux**: Configuration with project-specific session files (`.proj` files)
- **Terminal emulators**:
  - Alacritty config in `alacritty/alacritty.toml`
  - Ghostty config in `ghostty/config`
  - WezTerm config in `wezterm/wezterm.lua`

### Window Management (Linux)

- **i3 window manager**: Configuration in `i3/config`
- **i3status**: Status bar configuration
- **Resolution script**: `i3/set_default_resolution.sh` for display setup

### Additional Tools

- **Starship prompt**: Configuration in `starship/starship.toml`
- **NordVPN**: Toggle script in `nordvpn/nordvpn_toggle.sh`

## Platform-Specific Notes

### Linux (Debian-based)

- Detailed installation checklist in main README.md
- Hardware-specific fixes for MacBook Pro (WiFi, iSight camera, keyboard function keys)
- Manual compilation required for some tools (Neovim, lazygit)

### macOS

- Uses Homebrew for package management
- zk cli installation: `brew install zk`

## Key Dependencies and Tools

### Essential Tools

- **Neovim**: Built from source or package manager
- **Git**: Version control
- **Go**: For Go-based projects
- **Node.js/npm**: For various language servers and tools
- **zk**: Note-taking tool (install with `brew install zk` on macOS)

### Neovim Plugin Ecosystem

- **lazy.nvim**: Plugin manager
- **Mason**: LSP/DAP/linter installer
- **Treesitter**: Syntax highlighting
- **LSP**: Language server configurations
- **DAP**: Debug adapter configurations for C and Go
- **Completion**: cmp-based completion system
- **Markdown**: Live preview and rendering capabilities

## Development Workflow

1. **Making Neovim changes**: Edit configs in `neovim/nvim/lua/vinod/`
2. **Adding new plugins**: Create new file in `neovim/nvim/lua/vinod/plugins/`
3. **Custom plugins**: Develop in `neovim/nvim/dev-plugins/`
4. **Shell changes**: Modify appropriate zshrc file for your platform
5. **Terminal changes**: Update relevant terminal emulator config file

## Project Management (Tmux)

- Project session files end with `.proj` extension
- Located in `tmux/` directory
- Examples: `c.proj`, `neovim.proj`, `lua.proj`, `readwise.proj`

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

4. **Updated Documentation**: 
   - TodoHelp command reflects new keybinding scheme
   - CLAUDE.md updated with comprehensive keybinding documentation
   - Daily workflow updated to use new keybindings

**Benefits**:
- Consistent two-letter keybinding patterns (`ta`, `tl`, `to`, etc.)
- Logical grouping of all todo operations under `<leader>t` prefix
- No conflicts with existing plugin keybindings
- Reduced command namespace pollution (14 fewer commands)
- Better discoverability through organized submenu approach (`<leader>tv*` for filtering)
- Improved help system with clear categorization

**Migration Notes**: 
- Old keybindings like `<leader>vm`, `<leader>vp` are now `<leader>tvm`, `<leader>tvp`
- Commands like `:TodoDue`, `:TodoToday` are replaced by keybindings `<leader>tvd`, `<leader>tvt`
- All functionality remains accessible, just through more consistent patterns

### Todo Manager Buffer Modifiability Fix (2025-07-29)

**Issue**: When using `<leader>td` to update due dates via calendar picker, users encountered error `E5108: Buffer is not 'modifiable'` when working in filtered todo views.

**Root Cause**: The `update_todo_date_on_line()` function attempted to modify filtered view buffers that were set as non-modifiable, causing the operation to fail.

**Solution**: Enhanced the function with buffer modifiability management:
- **Temporary Modifiability**: Checks buffer's modifiable state and temporarily enables modification if needed
- **State Restoration**: Restores original modifiable state after update
- **Dual Update Logic**: When working in filtered views, also updates the actual todo file to maintain data consistency
- **Location**: `/Users/vinodnair/dotfiles/neovim/nvim/lua/vinod/todo_manager.lua:2685-2739`

**Technical Details**:
```lua
-- Check if buffer is modifiable and make it temporarily modifiable if needed
local buf = vim.api.nvim_get_current_buf()
local was_modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')

if not was_modifiable then
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
end

-- Replace the current line
vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

-- Restore original modifiable state
if not was_modifiable then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end
```

**Impact**: Users can now successfully update due dates using `<leader>td` from both raw todo files and filtered views without encountering buffer modification errors.

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
