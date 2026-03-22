# Tmux Projects & Scripts Development Documentation

Tmux session management system with project-based workflows, an interactive project generator, and a smart session picker.

**Core Files**:
- `tmux/.tmux.conf` - Main tmux configuration
- `tmux/scripts/smart-sessionizer.sh` - Interactive session picker (alias: `ss`)
- `tmux/scripts/create-project.sh` - Interactive .proj file generator
- `tmux/projects/*.proj` - Project session files

## Directory Structure

```
dotfiles/tmux/
├── .tmux.conf                  # Main tmux config
├── .tmux.mac.conf              # macOS-specific config (clipboard)
├── data/                       # Persistent data files
│   └── pinned_sessions         # Pinned/favorite session names (syncs via git)
├── projects/                   # Project session files
│   ├── nvconf.proj
│   ├── cqm.proj
│   ├── todo.proj
│   └── ... (12 .proj files)
├── scripts/                    # All shell scripts (consolidated)
│   ├── smart-sessionizer.sh    # Session picker (ss alias)
│   ├── create-project.sh       # Project generator
│   ├── tmux-sessionizer.sh     # Legacy session picker
│   ├── pomodoro.sh             # Pomodoro timer
│   ├── get_cpu_usage.sh        # Status bar scripts
│   ├── get_battery_status.sh
│   ├── get_memory_usage.sh
│   ├── get_wifi_status.sh
│   ├── get_network_stats.sh
│   ├── get_git_status.sh
│   ├── get_gpu_usage.sh
│   ├── get_weather.sh
│   ├── get_ai_model.sh
│   ├── get_copilot_model.sh
│   └── get_ollama_model.sh
├── SESSION_CHANGES.md
└── STATUS_BAR_DEV.md
```

## Script Consolidation

All shell scripts were moved from `tmux/` root into `tmux/scripts/` for organization. References updated in:

| File | What changed |
|------|-------------|
| `tmux/.tmux.conf` | All `~/dotfiles/tmux/<script>.sh` → `~/dotfiles/tmux/scripts/<script>.sh` |
| `zsh/zshrc_mac` | `ss` alias path, `tmux_sessionizer` widget `BUFFER` path |
| `zsh/zshrc_linux` | `ss` alias path |

## Smart Sessionizer (`ss`)

Interactive fzf-based session picker. Accessible via:
- **Shell alias**: `ss` (both macOS and Linux zshrc)
- **Tmux keybinding**: `Ctrl-a f` (opens in popup)
- **Terminal keybinding**: `Ctrl-S` (macOS zshrc widget)

### Menu sections
| Section | Icon | Description |
|---------|------|-------------|
| Active Sessions | `📌` / `●` | Running tmux sessions — pinned first, then MRU sorted, with uptime |
| Recent (Inactive) | `◆` | Last 3 used sessions no longer active, with date (MM/DD/YYYY) |
| Create New Session | `○` | Available .proj files (creates and switches) |
| Tools | `+` | Create New Project (launches generator) |
| Kill tmux server | `⚠` | Terminates all sessions (with confirmation) |

### Controls
| Key | Action | Behavior after action |
|-----|--------|----------------------|
| **Enter** | Select/launch session | Switches to session, closes picker |
| **Ctrl-d** | Kill selected active session (with confirmation) | Stays in picker (refreshed list) |
| **Ctrl-x** | Toggle pin on selected active session | Stays in picker (refreshed list) |
| **Esc** | Cancel | Closes picker |
| **Ctrl-p/n** | Navigate up/down | fzf default |

Both Ctrl-d and Ctrl-x use `exec bash "$SCRIPT_PATH"` to re-launch the picker after the action, so the user stays in the session management flow without the popup closing.

### Data files
| File | Location | Purpose |
|------|----------|---------|
| Session history | `${XDG_DATA_HOME:-~/.local/share}/tmux/session_history` | Tracks session access timestamps (machine-local, not in git) |
| Pinned sessions | `~/dotfiles/tmux/data/pinned_sessions` | One session name per line (in repo, syncs across machines) |

### How it finds .proj files

The `find_proj_file()` function uses a two-step lookup:
1. **Direct filename match** (case-insensitive): `find -iname "${name}.proj"` — handles cases like `aerc` → `aerc.proj`
2. **Reverse lookup by session name**: Searches all `.proj` file contents for `has-session.*-t.*${name}` — handles cases where filename differs from session name (e.g., `dsa.proj` creates session `LearnDSA`)

This is necessary because 12 of 13 `.proj` files have different filenames than the session names they create (e.g., `nvconf.proj` → `NeovimConf`, `cqm.proj` → `CQM`).

### How it launches .proj files
1. Parses target session name from `tmux attach -t <name>` line in the .proj file
2. If session doesn't exist: runs .proj in background, waits 0.5s for creation
3. Switches to the session

### Helper functions

| Function | Purpose |
|----------|---------|
| `extract_session_name()` | Strips icons, uptime/date suffix, and whitespace from a menu line to get the session name |
| `find_proj_file()` | Finds a .proj file by name (direct match) or by session name (reverse lookup) |
| `launch_proj_file()` | Runs a .proj file and switches to the created session |
| `log_session_access()` | Appends `timestamp\|name` to session history |
| `get_recent_sessions()` | Returns N most recently used unique session names from history |
| `format_uptime()` | Converts session_created timestamp to human-readable uptime (e.g., `2h 15m`) |
| `format_epoch_date()` | Cross-platform epoch → MM/DD/YYYY formatting |
| `reverse_lines()` | Cross-platform line reversal (`tac` on Linux, `tail -r` on macOS) |
| `is_pinned()` / `toggle_pin()` | Check/toggle pin status in the pin file |

### Cross-platform notes
- `reverse_lines()` wrapper: uses `tac` on Linux, `tail -r` on macOS
- `format_epoch_date()` wrapper: tries `date -r` (macOS) then `date -d @` (Linux)
- Pin emoji via `printf '\xf0\x9f\x93\x8c'` for bash 3.2 compatibility
- Pin file removal uses `grep -vx` + `|| true` + temp file (avoids `sed -i` portability issue; `|| true` handles `grep` exit code 1 when file becomes empty)
- `extract_session_name()` avoids emoji in sed patterns — strips trailing `(...)` then leading non-alphanumeric chars
- `find_proj_file()` reverse lookup uses `grep -l` with a flexible pattern to handle `.proj` format variations (`-t Name`, `-t 'Name'`, `-t='Name'`, extra spaces)

## Project Generator (`create-project.sh`)

Interactive script that generates `.proj` files. Launched from the `ss` menu ("Create New Project") or directly via `bash ~/dotfiles/tmux/scripts/create-project.sh`.

### Prompts
| # | Prompt | Default | Validation |
|---|--------|---------|------------|
| 1 | Session name | — | Non-empty, no spaces |
| 2 | Working directory | — | Must exist (offers to create) |
| 3 | First window name | `Neovim` | — |
| 4 | Vim target (file/dir) | `.` | — |
| 5 | AI assistant | `claude` | Options: claude, opencode, codex, none |
| 6 | Console window | `Y` | — |
| 7 | Lazygit window | `Y` | — |
| 8 | Custom windows | `N` | Loop: name + command until empty |
| 9 | Output filename | lowercase session name | Auto-appends `.proj` |

### Output
Generated `.proj` files are placed in `~/dotfiles/tmux/projects/` and made executable.

### Cross-platform notes
- Uses `tr '[:upper:]' '[:lower:]'` for case conversion (macOS ships bash 3.2, lacks `${var,,}`)
- Uses `eval echo` to expand `~` for directory validation
- No GNU-specific flags

## .proj File Template

All project files follow this structure:

```bash
#!/bin/bash
# tmux setup for SESSION_NAME

if ! tmux has-session -t SESSION_NAME
then

# WindowName
tmux new-session -s SESSION_NAME -n WindowName -d
tmux send-keys -t SESSION_NAME:1 'cd WORK_DIR' C-m
tmux send-keys -t SESSION_NAME:1 'vim .' C-m

# Horizontal split with AI assistant (optional)
tmux split-window -h -t SESSION_NAME:1
tmux send-keys -t SESSION_NAME:1.2 'cd WORK_DIR' C-m
tmux send-keys -t SESSION_NAME:1.2 'claude' C-m

# Console Window (optional)
tmux new-window -n Console -t SESSION_NAME
tmux send-keys -t SESSION_NAME:2  'cd WORK_DIR' C-m
tmux send-keys -t SESSION_NAME:2  'clear' C-m

# Lazygit (optional)
tmux new-window -n Lazygit -t SESSION_NAME
tmux send-keys -t SESSION_NAME:3  'cd WORK_DIR' C-m
tmux send-keys -t SESSION_NAME:3  'lg' C-m

# Select first window
tmux select-window -t SESSION_NAME:1
tmux select-pane -t SESSION_NAME:1.1
fi

# Attach or switch to session
if [ -n "$TMUX" ]; then
    tmux switch-client -t SESSION_NAME
else
    tmux attach -t SESSION_NAME
fi
```

### Key conventions
- Window indices start at 1 (set by `base-index 1` in `.tmux.conf`)
- Pane indices start at 1 (set by `pane-base-index 1`)
- Session names use PascalCase (e.g., `NeovimConf`, `TodoProject`)
- The attach/switch block at the end handles both inside-tmux and outside-tmux contexts

## Tmux Keybindings Reference

### Session & Window Management
| Key | Description |
|-----|-------------|
| `Ctrl-a f` | Open session picker popup |
| `Ctrl-a Q` | Kill session (with confirmation) |
| `Ctrl-a c` | New window at current path |
| `Ctrl-a v` | Vertical split (side-by-side) at current path |
| `Ctrl-a s` | Horizontal split (top-bottom) at current path |

### Pomodoro Timer
| Key | Description |
|-----|-------------|
| `Ctrl-a t` | Start pomodoro |
| `Ctrl-a T` | Pause pomodoro |
| `Ctrl-a x` | Cancel pomodoro |
| `Ctrl-a M-t` | Reset pomodoro |

### Navigation
| Key | Description |
|-----|-------------|
| `Ctrl-h/j/k/l` | Smart pane switching (vim-aware) |
| `Ctrl-a h/j/k/l` | Fallback pane switching (with prefix) |
| `Ctrl-a H/J/K/L` | Resize panes (repeatable) |
| `Ctrl-a M-h/l/k/j` | Swap panes directionally |

## Status Bar Scripts

All in `tmux/scripts/`, called from `.tmux.conf` status-right:

| Script | What it shows |
|--------|--------------|
| `get_git_status.sh` | Branch name, dirty state, ahead/behind |
| `pomodoro.sh status` | Timer icon and countdown |
| `get_weather.sh` | Weather (minimal or verbose, toggled by `weather-toggle` alias) |
| `get_cpu_usage.sh` | CPU % with color coding (yellow ≥30%, red ≥80%) |
| `get_gpu_usage.sh` | GPU usage |
| `get_network_stats.sh` | Network throughput |
| `get_memory_usage.sh` | Memory usage |
| `get_wifi_status.sh` | WiFi connection |
| `get_battery_status.sh` | Battery level with Nerd Font icons |

Status bar updates every 1 second (`status-interval 1`).
