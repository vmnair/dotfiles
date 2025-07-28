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

#### **Key Commands**:
- **Adding Todos**:
  - `:TodoAdd <desc> | Show: mm-dd-yyyy | Due: mm-dd-yyyy` - Full syntax with show/due dates
  - `:TodoAdd <desc> /show /due` - Sequential calendar pickers
  - `:TodoBuild` - Interactive step-by-step todo creation with calendar pickers
  - `:TodoMed`, `:TodoOMS`, `:Todo` - Quick category additions with show/due date support
- **Viewing Todos**:
  - `:TodoList` - List currently active (visible) todos
  - `:TodoScheduled` - List all scheduled (future) todos with show dates
  - `:TodoUpcoming [days]` - List todos scheduled for next N days (default 7)
  - `:TodoDue`, `:TodoPastDue`, `:TodoToday` - Filter by due dates
- **File Operations**:
  - `:TodoOpen` - Open filtered view of active todos (only current, not scheduled)
  - `:TodoOpenRaw` - Open raw todos file for editing (includes scheduled todos)
  - `:TodoOpenCompleted` - Open completed todos file for viewing/editing
  - `tt` - Toggle completion in todo files (works in filtered view and raw files)
  - `<leader>vd`, `<leader>vm`, `<leader>vo`, `<leader>vp` - Filter views

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

#### **Daily Workflow**:
1. **Morning Review**: `:TodoOpen` - See only current active todos (filtered view)
2. **Add New Todos**: `:Todo description /show mm-dd-yyyy /due mm-dd-yyyy` 
3. **Complete Todos**: Press `tt` on any todo line (works in filtered view)
4. **Check Upcoming**: `:TodoScheduled` or `:TodoUpcoming [days]`
5. **Reactivate Completed**: `:TodoOpenCompleted` then `tt` on completed todo
6. **View All (Admin)**: `:TodoOpenRaw` - See all todos including scheduled

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
