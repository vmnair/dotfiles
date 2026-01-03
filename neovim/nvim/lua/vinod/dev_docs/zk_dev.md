# ZK (Zettelkasten) Development Documentation

## System Overview

Personal knowledge management system using zk-nvim plugin for Neovim with shell integration for quick note creation and navigation. Supports Zettelkasten-style note-taking with tags, templates, and todo integration.

## CURRENT STATUS (2025-01-02)

**Core Functionality**: All major features working correctly.
**Picker**: Using fzf_lua for note selection.
**Keybindings**: Changed from `<leader>z*` to `<leader>n*` prefix.
**Shell Integration**: Interactive folder picker with fzf when `zk` called with no args.

**Core Files**:
- **Neovim Plugin**: `neovim/nvim/lua/vinod/plugins/zk.lua`
- **Shell Functions**: `zsh/zk_functions.zsh`
- **ZK Config**: `~/Library/CloudStorage/Dropbox/notebook/.zk/config.toml`

## Configuration

**Notebook Location**: `~/Library/CloudStorage/Dropbox/notebook/`

**Environment Variable**:
```bash
export ZK_NOTEBOOK_DIR="$HOME/Library/CloudStorage/Dropbox/notebook"
```

**Picker**: fzf_lua (changed from snacks_picker)

## Neovim Keybindings

### Core ZK Commands
| Keymap | Description |
|--------|-------------|
| `<leader>nn` | Create new note with title prompt |
| `<leader>no` | Open notes (sorted by modified date) |
| `<leader>nt` | Browse notes by tags |
| `<leader>nf` | Search notes by query (normal mode) |
| `<leader>nf` | Search notes matching visual selection (visual mode) |

### Text & Todo Integration
| Keymap | Description |
|--------|-------------|
| `<leader>na` | Add word under cursor as hashtag after `---` separator |
| `<leader>nT` | Create todo from current line (with category/date picker) |

### Help & Aliases
| Keymap | Description |
|--------|-------------|
| `<leader>nh` | Show comprehensive ZK help window |

## Shell Functions (zk_functions.zsh)

### zk() Wrapper Function
When called with no arguments, shows an interactive folder picker using fzf:
- **Enter**: Create new note in selected folder (prompts for title)
- **Ctrl-e**: Edit existing file in selected folder (shows file picker)

When called with arguments, passes through to the real `zk` binary.

### zkdaily()
Quick daily journal entry creator:
```bash
zkdaily           # Creates "Daily Journal" in journal folder
zkdaily "Title"   # Creates note with custom title
```

### zkhelp()
Displays available zk aliases from config.toml in the terminal.

### Aliases
- `search` → `zk search` - Quick search alias

## Key Features

### Hashtag Management (`<leader>na`)
Adds word under cursor as hashtag to the note's tag section:
- Searches for `---` separator line from end of file
- If found, appends hashtag after separator (on existing tag line or new line)
- If no separator, adds `---` and hashtag at end of file
- Prevents duplicate hashtags
- Converts word to lowercase, removes special characters

### Todo Integration (`<leader>nT`)
Creates todo from current line with interactive pickers:
1. Category selection (from todo_manager categories)
2. Show date picker (optional)
3. Due date picker (optional)
4. Creates todo in active-todos.md

### Help Window (`<leader>nh`)
Floating window with:
- Core ZK commands and keybindings
- Built-in ZK commands (`:Zk...`)
- Common ZK aliases from config.toml
- Workflow tips
- Syntax highlighting for readability
- Close with `q` or `ESC`

## Common ZK Aliases (from config.toml)

| Alias | Description |
|-------|-------------|
| `zk daily` | Create daily journal entry |
| `zk oms` | Create OMS note |
| `zk oms-staff` | Create OMS staff discussion |
| `zk oms-admin` | Create OMS admin discussion |
| `zk practice` | Create practice note |
| `zk research` | Create research note |
| `zk card` | Create cardiology note |
| `zk hca` | Create administration note |
| `zk lua` | Create lua development note |
| `zk c` | Create C development note |
| `zk go` | Create Go development note |
| `zk ls` | List recent notes |
| `zk search` | Search by tags |
| `zk editlast` | Edit last modified note |
| `zk config` | Edit zk configuration |

## Built-in ZK Commands

| Command | Description |
|---------|-------------|
| `:ZkNew` | Create new note |
| `:ZkNotes` | List/search notes |
| `:ZkTags` | Browse by tags |
| `:ZkMatch` | Search in visual selection |
| `:ZkCd` | Change to zk notebook directory |
| `:ZkIndex` | Index the notebook |

## Daily Workflow

1. **Quick note from shell**: `zk` → select folder → enter title
2. **Quick note from Neovim**: `<leader>nn` → enter title
3. **Browse recent**: `<leader>no` to see recent notes
4. **Find by tag**: `<leader>nt` to browse tags
5. **Search content**: `<leader>nf` then type search term
6. **Add hashtag**: Place cursor on word, then `<leader>na`
7. **Line to todo**: Place cursor on line, then `<leader>nT`
8. **Get help**: `<leader>nh` for comprehensive help window

## Recent Updates (2025-01-02)

### Keybinding Refactor
- Changed all keybindings from `<leader>z*` to `<leader>n*` prefix
- More intuitive for "notes" functionality

### Hashtag Function Refactor
- Changed from visual selection to word under cursor
- Improved placement logic to find `---` separator
- Tags now added after separator line instead of at file end

### Shell Integration
- Added `zk()` wrapper function with interactive folder picker
- Supports both new note creation and existing file editing
- Added `zkdaily()` for quick journal entries
- Changed `ZK_NOTEBOOK_DIR` to use real Dropbox path instead of symlink

### Picker Change
- Switched from `snacks_picker` to `fzf_lua` for consistency
