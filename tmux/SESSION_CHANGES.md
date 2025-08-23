# Tmux Session Management Implementation

## Date: 2025-08-23

## Summary
Implemented a unified tmux session management system that works consistently from both terminals and within tmux sessions, eliminating prompts and providing automatic session detachment behavior.

## Problem Statement
User wanted:
1. `C-s` in terminal to show tmux session popup
2. `C-a s` in tmux to show session popup (existing)
3. When selecting a session, automatically detach current session and switch to selected
4. No prompts asking what to do with current session
5. If selecting current session, just close popup
6. Popup should always close after selection
7. Detached sessions should appear in future session lists

## Solution Implemented

### 1. Created `smart-sessionizer.sh`
**Location**: `/Users/vinodnair/dotfiles/tmux/smart-sessionizer.sh`

**Key Features**:
- Detects if running inside tmux vs terminal context
- Uses appropriate fzf display (popup in tmux, full terminal otherwise)
- Eliminates all user prompts for session switching
- Automatically detaches current session when switching to different session
- If selecting current session, just exits (closes popup)
- Handles both existing sessions and new project creation

**Logic Flow**:
```bash
# Inside tmux:
if current_session == selected_session:
    exit 0  # Just close popup
else:
    tmux switch-client -t selected_session  # Auto-detaches current

# Outside tmux:
tmux attach-session -t selected_session
```

### 2. Updated Configuration Files

#### A. Tmux Configuration (`/Users/vinodnair/dotfiles/tmux/.tmux.conf`)
**Change**: Line 40
```bash
# OLD:
bind-key s display-popup -E -w 80% -h 60% -d "#{pane_current_path}" "bash ~/dotfiles/tmux/tmux-sessionizer.sh"

# NEW:
bind-key s display-popup -E -w 80% -h 60% -d "#{pane_current_path}" "bash ~/dotfiles/tmux/smart-sessionizer.sh"
```

#### B. Zsh Configuration (`/Users/vinodnair/dotfiles/zsh/zshrc_mac`)
**Change**: Lines 167-174
```bash
# OLD:
tmux_sessionizer() {
  zle push-input
  BUFFER="$HOME/dotfiles/tmux/tmux-sessionizer.sh"
  zle accept-line
}
zle -N tmux_sessionizer
bindkey '^F' tmux_sessionizer # bind the widget to Ctrl+F

# NEW:
tmux_sessionizer() {
  zle push-input
  BUFFER="$HOME/dotfiles/tmux/smart-sessionizer.sh"
  zle accept-line
}
zle -N tmux_sessionizer
bindkey '^S' tmux_sessionizer # bind the widget to Ctrl+S
```

## User Experience

### Before Changes:
1. `C-a s` in tmux → popup with fzf → select session → prompted for action (switch/kill-current/detach)
2. No consistent way to access sessionizer from terminal
3. Multiple user interactions required

### After Changes:
1. **Terminal**: `Ctrl+S` → fzf in terminal → select → automatic switch
2. **Tmux**: `Ctrl+A s` → popup with fzf → select → automatic detach & switch
3. **Same session selected**: Just closes popup/fzf
4. **Zero prompts**: Everything happens automatically

## Files Modified
1. **Created**: `/Users/vinodnair/dotfiles/tmux/smart-sessionizer.sh` (executable)
2. **Modified**: `/Users/vinodnair/dotfiles/tmux/.tmux.conf` (line 40)
3. **Modified**: `/Users/vinodnair/dotfiles/zsh/zshrc_mac` (lines 167-174)

## Original Files Preserved
- `/Users/vinodnair/dotfiles/tmux/tmux-sessionizer.sh` - kept as backup, no longer used

## Technical Details

### Script Comparison: smart-sessionizer.sh vs tmux-sessionizer.sh

#### Key Behavioral Differences

**Prompt Elimination**:
- **smart-sessionizer.sh**: Zero user prompts - automatically detaches/switches
- **tmux-sessionizer.sh**: Shows interactive fzf prompt: "switch/kill-current/detach"

**Current Session Handling**:
- **smart-sessionizer.sh**: Detects if already in selected session and exits (lines 61-64)
- **tmux-sessionizer.sh**: No current session detection, always prompts

**Context Awareness**:
- **smart-sessionizer.sh**: Different fzf heights for terminal (50%) vs tmux (40%) contexts
- **tmux-sessionizer.sh**: Fixed 40% height regardless of context

#### Code Structure Analysis

**Session Switching Logic**:
```bash
# smart-sessionizer.sh (automatic)
if [[ "$current_session" == "$session_name" ]]; then
    exit 0  # Just close popup
fi
tmux switch-client -t "$session_name"  # Auto-detaches

# tmux-sessionizer.sh (interactive)
action=$(printf "switch\nkill-current\ndetach" | fzf ...)
case "$action" in
    "switch") tmux switch-client -t "$session_name" ;;
    # ... more cases
esac
```

**Project Creation**:
```bash
# smart-sessionizer.sh (streamlined)
if [[ -n "$TMUX" ]]; then
    tmux detach-client
    "$project_file"
else
    "$project_file"
fi

# tmux-sessionizer.sh (with prompts)
if [[ -n "$TMUX" ]]; then
    action=$(printf "switch\nkill-current\ndetach" | fzf ...)
    case "$action" in
        *) "$project_file" ;;
    esac
else
    "$project_file"
fi
```

### Session Detection Logic
```bash
if [[ -n "$TMUX" ]]; then
    # Inside tmux context
    current_session=$(tmux display-message -p '#S')
    if [[ "$current_session" == "$session_name" ]]; then
        exit 0  # Already in selected session
    fi
    tmux switch-client -t "$session_name"  # Auto-detaches current
else
    # Outside tmux context
    tmux attach-session -t "$session_name"
fi
```

### Context-Aware Display
- **Inside tmux**: Uses fzf normally (popup handled by tmux config)
- **Outside tmux**: Uses fzf in full terminal mode

## Testing Notes
- Works with existing active sessions (marked with `[ACTIVE]`)
- Works with new project files (marked with `[NEW]`)
- Maintains all original project file functionality
- Session detachment preserves running processes
- Detached sessions appear in subsequent session lists

## Future Considerations
- System works with any terminal emulator, not just Ghostty
- Can be extended to other shell configurations (zsh, bash)
- Smart-sessionizer pattern could be applied to other tmux workflows

## Rollback Instructions
If issues arise:
1. Restore tmux config: `bind-key s display-popup -E -w 80% -h 60% -d "#{pane_current_path}" "bash ~/dotfiles/tmux/tmux-sessionizer.sh"`
2. Restore zsh keybinding: `bindkey '^F' tmux_sessionizer`
3. Update zsh function to use original script: `BUFFER="$HOME/dotfiles/tmux/tmux-sessionizer.sh"`