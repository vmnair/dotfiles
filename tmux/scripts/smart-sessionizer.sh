#!/usr/bin/env bash
set -euo pipefail

# Smart tmux session picker that works in both terminal and tmux contexts
# Usage:
#   - From terminal (C-s): Run with fzf directly
#   - From tmux (C-a f): Run in popup (handled by tmux config)
#
# Controls (fzf keybindings):
#   Enter    - Select/launch session
#   Ctrl-d   - Kill selected active session (with confirmation)
#   Ctrl-x   - Toggle pin on selected active session
#   Ctrl-p/n - Navigate up/down (fzf default)
#   Esc      - Cancel

# Resolve absolute script path for exec re-launch (handles ~/... invocations)
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# =============================================================================
# History file (XDG-compliant, machine-local)
# =============================================================================
HISTORY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux"
HISTORY_FILE="${HISTORY_DIR}/session_history"
mkdir -p "$HISTORY_DIR"
touch "$HISTORY_FILE"

# Prune history to last 500 entries
if [ "$(wc -l < "$HISTORY_FILE")" -gt 500 ]; then
    tail -n 500 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
fi

# =============================================================================
# Pin file (in dotfiles repo, syncs across machines)
# =============================================================================
PIN_FILE="$HOME/dotfiles/tmux/data/pinned_sessions"
mkdir -p "$(dirname "$PIN_FILE")"
touch "$PIN_FILE"

# Pin icon (bash 3.2 compatible — no \U escapes)
PIN_ICON=$(printf '\xf0\x9f\x93\x8c')  # 📌

# =============================================================================
# Cross-platform helpers
# =============================================================================

# Reverse lines: macOS has tail -r, Linux has tac
reverse_lines() {
    if command -v tac >/dev/null 2>&1; then
        tac
    else
        tail -r
    fi
}

# Format epoch timestamp as MM/DD/YYYY
format_epoch_date() {
    local ts="$1"
    date -r "$ts" +"%m/%d/%Y" 2>/dev/null || date -d "@${ts}" +"%m/%d/%Y" 2>/dev/null || echo "unknown"
}

# Format uptime from session_created timestamp
format_uptime() {
    local created="$1"
    local now
    now=$(date +%s)
    local diff=$((now - created))

    local days=$((diff / 86400))
    local hours=$(( (diff % 86400) / 3600 ))
    local mins=$(( (diff % 3600) / 60 ))

    if [ "$days" -gt 0 ]; then
        echo "${days}d"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}h ${mins}m"
    else
        echo "${mins}m"
    fi
}

# =============================================================================
# History functions
# =============================================================================

log_session_access() {
    local name="$1"
    echo "$(date +%s)|${name}" >> "$HISTORY_FILE"
}

get_last_access() {
    local name="$1"
    grep "|${name}$" "$HISTORY_FILE" | tail -1 | cut -d'|' -f1
}

get_recent_sessions() {
    local limit="${1:-3}"
    reverse_lines < "$HISTORY_FILE" | cut -d'|' -f2 | awk '!seen[$0]++' | head -n "$limit"
}

# =============================================================================
# Pin functions
# =============================================================================

is_pinned() {
    grep -qx "$1" "$PIN_FILE" 2>/dev/null
}

toggle_pin() {
    local name="$1"
    if is_pinned "$name"; then
        # grep -vx exits 1 when no lines remain, so avoid && to ensure mv always runs
        grep -vx "$name" "$PIN_FILE" > "${PIN_FILE}.tmp" || true
        mv "${PIN_FILE}.tmp" "$PIN_FILE"
    else
        echo "$name" >> "$PIN_FILE"
    fi
}

# =============================================================================
# Extract session name from a menu line (strips icons, uptime, whitespace)
# Works for: "  ● Name (2h)", "  📌 Name (3d)", "  ◆ Name (03/21/2026)"
# =============================================================================

extract_session_name() {
    echo "$1" | sed 's/ ([^)]*) *$//' | sed 's/^[^a-zA-Z0-9]*//'
}

# =============================================================================
# Launch .proj file (reusable for both ○ and ◆ handlers)
# =============================================================================

launch_proj_file() {
    local project_file="$1"
    local session_name="$2"

    chmod +x "$project_file"
    local target_session
    target_session=$(grep -E "attach.*-t" "$project_file" | sed 's/.*-t //' | head -1)

    if [[ -z "$target_session" ]]; then
        echo "Error: Could not parse session name from $project_file"
        echo "Ensure the .proj file contains: tmux attach -t <session_name>"
        read -p "Press Enter to continue..."
        return 1
    fi

    if [[ -n "$TMUX" ]]; then
        if ! tmux has-session -t "$target_session" 2>/dev/null; then
            bash "$project_file" >/dev/null 2>&1 &
            sleep 0.5

            if ! tmux has-session -t "$target_session" 2>/dev/null; then
                echo "Error: Failed to create session '$target_session'"
                echo "Check $project_file for errors"
                read -p "Press Enter to continue..."
                return 1
            fi
        fi
        log_session_access "$target_session"
        tmux switch-client -t "$target_session"
    else
        log_session_access "$target_session"
        "$project_file"
    fi
}

# =============================================================================
# Find .proj file by session name (searches POSSIBLE_PROJECT_DIRS)
# =============================================================================

find_proj_file() {
    local name="$1"
    # First: try direct filename match (case-insensitive)
    for dir in "${POSSIBLE_PROJECT_DIRS[@]}"; do
        local found
        found=$(find "$dir" -maxdepth 3 -iname "${name}.proj" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            echo "$found"
            return 0
        fi
    done
    # Second: reverse lookup — search .proj files for one that creates this session
    # Handles cases where filename differs from session name (e.g. dsa.proj → LearnDSA)
    # Pattern is flexible: matches -t Name, -t 'Name', -t='Name', extra spaces, trailing ;
    for dir in "${POSSIBLE_PROJECT_DIRS[@]}"; do
        local found
        found=$(find "$dir" -maxdepth 3 -name "*.proj" -print0 2>/dev/null | xargs -0 grep -l "has-session" 2>/dev/null | xargs grep -Fl "$name" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            echo "$found"
            return 0
        fi
    done
    return 1
}

# =============================================================================
# Gather data
# =============================================================================

# Possible directories to search for .proj files (auto-detected)
POSSIBLE_PROJECT_DIRS=(
    "$HOME/dotfiles/tmux/projects"
    # "$HOME/projects"
    # "$HOME/dotfiles"
    # "$HOME/dev"
    # "$HOME/code"
    # "$HOME/work"
)

# Get session data with creation time and last attached time
session_data=$(tmux list-sessions -F "#{session_name}|#{session_created}|#{session_last_attached}" 2>/dev/null)
active_names=$(echo "$session_data" | cut -d'|' -f1 | grep -v '^$')

# Find .proj files in existing directories
project_files=""
for dir in "${POSSIBLE_PROJECT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        found=$(find "$dir" -maxdepth 3 -type f -name "*.proj" 2>/dev/null)
        if [[ -n "$found" ]]; then
            project_files+="$found"$'\n'
        fi
    fi
done
project_files=$(echo "$project_files" | grep -v '^$' | sort -u)

# =============================================================================
# Build Active Sessions section (pinned first, then MRU sorted, with uptime)
# =============================================================================

pinned_lines=""
regular_lines=""

if [[ -n "$session_data" ]]; then
    # Sort sessions by MRU: use history file timestamp, fallback to session_last_attached
    sorted_sessions=$(
        while IFS='|' read -r sname screated slast; do
            [ -z "$sname" ] && continue
            history_ts=$(get_last_access "$sname")
            sort_key="${history_ts:-$slast}"
            echo "${sort_key}|${sname}|${screated}"
        done <<< "$session_data" | sort -t'|' -k1 -rn
    )

    while IFS='|' read -r sort_key sname screated; do
        [ -z "$sname" ] && continue
        uptime_str=$(format_uptime "$screated")
        if is_pinned "$sname"; then
            pinned_lines+="  ${PIN_ICON} ${sname} (${uptime_str})"$'\n'
        else
            regular_lines+="  ● ${sname} (${uptime_str})"$'\n'
        fi
    done <<< "$sorted_sessions"
fi

# =============================================================================
# Build Recent (Inactive) section
# =============================================================================

recent_section=""
recent_count=0

while IFS= read -r recent_name; do
    [ -z "$recent_name" ] && continue
    # Skip if currently active
    if echo "$active_names" | grep -qx "$recent_name"; then
        continue
    fi
    # Get timestamp and format as date
    last_ts=$(get_last_access "$recent_name")
    if [ -n "$last_ts" ]; then
        last_date=$(format_epoch_date "$last_ts")
    else
        last_date="unknown"
    fi
    recent_section+="  ◆ ${recent_name} (${last_date})"$'\n'
    recent_count=$((recent_count + 1))
    [ "$recent_count" -ge 3 ] && break
done <<< "$(get_recent_sessions 10)"

# =============================================================================
# Assemble menu
# =============================================================================

all_options=""

# Active Sessions (pinned first, then MRU sorted)
if [[ -n "$pinned_lines" || -n "$regular_lines" ]]; then
    all_options="━━ Active Sessions ━━"$'\n'
    [ -n "$pinned_lines" ] && all_options+="$pinned_lines"
    [ -n "$regular_lines" ] && all_options+="$regular_lines"
    # Remove trailing newline
    all_options=$(printf '%s' "$all_options" | sed '/^$/d')
fi

# Recent (Inactive)
if [[ -n "$recent_section" ]]; then
    [ -n "$all_options" ] && all_options+=$'\n'$'\n'
    all_options+="━━ Recent (Inactive) ━━"$'\n'
    all_options+=$(printf '%s' "$recent_section" | sed '/^$/d')
fi

# Create New Session
if [[ -n "$project_files" ]]; then
    project_names=$(echo "$project_files" | xargs -I {} basename {} .proj | sed 's/^/  ○ /')
    if [[ -n "$all_options" ]]; then
        all_options+=$'\n'$'\n'"━━ Create New Session ━━"$'\n'"$project_names"
    else
        all_options="━━ Create New Session ━━"$'\n'"$project_names"
    fi
fi

# Tools section
if [[ -n "$all_options" ]]; then
    all_options+=$'\n'$'\n'"━━ Tools ━━"$'\n'"  + Create New Project"
else
    all_options="━━ Tools ━━"$'\n'"  + Create New Project"
fi

# Kill server option
all_options+=$'\n'$'\n'"━━━━━━━━━━━━━━━━━━━━━━"$'\n'"  ⚠ Kill tmux server"

if [[ -z "$all_options" ]]; then
    echo "No sessions or project directories found"
    exit 1
fi

# =============================================================================
# Enhanced preview command
# =============================================================================

preview_cmd='
  line={}
  PIN_ICON=$(printf '"'"'\xf0\x9f\x93\x8c'"'"')
  if [[ "$line" == *"● "* ]] || [[ "$line" == *"$PIN_ICON"* ]]; then
    # Active session (regular or pinned) — strip trailing (uptime) then leading non-alnum
    session=$(echo "$line" | sed "s/ ([^)]*) *$//;s/^[^a-zA-Z0-9]*//")

    # Working directory from first window
    work_dir=$(tmux display-message -t "${session}:1" -p "#{pane_current_path}" 2>/dev/null)
    if [ -n "$work_dir" ]; then
        echo "Dir: $work_dir"
        echo ""
    fi

    # Git info
    if [ -n "$work_dir" ] && [ -d "${work_dir}/.git" ]; then
        branch=$(git -C "$work_dir" branch --show-current 2>/dev/null)
        last_commit=$(git -C "$work_dir" log --oneline -1 2>/dev/null)
        if [ -n "$branch" ]; then
            echo "Branch: $branch"
            [ -n "$last_commit" ] && echo "  $last_commit"
            echo ""
        fi
    fi

    # Uptime
    created=$(tmux display-message -t "$session" -p "#{session_created}" 2>/dev/null)
    if [ -n "$created" ]; then
        now=$(date +%s)
        diff=$((now - created))
        days=$((diff / 86400))
        hours=$(( (diff % 86400) / 3600 ))
        mins=$(( (diff % 3600) / 60 ))
        if [ "$days" -gt 0 ]; then
            echo "Uptime: ${days}d ${hours}h"
        elif [ "$hours" -gt 0 ]; then
            echo "Uptime: ${hours}h ${mins}m"
        else
            echo "Uptime: ${mins}m"
        fi
        echo ""
    fi

    # Window list
    echo "Windows:"
    tmux list-windows -t "$session" -F "  #{window_index}: #{window_name} (#{pane_current_command})" 2>/dev/null

  elif [[ "$line" == *"◆ "* ]]; then
    # Recent inactive session
    name=$(echo "$line" | sed "s/.*◆ //;s/ (.*//" | xargs)
    date_str=$(echo "$line" | grep -o "([^)]*)" | tr -d "()")
    echo "Last used: $date_str"
    echo ""
    # Find .proj file: try direct name first, then reverse lookup by session name
    proj_file="$HOME/dotfiles/tmux/projects/${name}.proj"
    if [ ! -f "$proj_file" ]; then
        proj_file=$(find "$HOME/dotfiles/tmux/projects" -maxdepth 3 -name "*.proj" -exec grep -l "has-session.*-t[= ]*'"'"'*${name}" {} \; 2>/dev/null | head -1)
    fi
    if [ -n "$proj_file" ] && [ -f "$proj_file" ]; then
        echo "Will recreate from: $(basename "$proj_file")"
        echo ""
        work_dir=$(grep "cd " "$proj_file" | head -1 | sed "s/.*cd //;s/'"'"'.*//" | xargs)
        [ -n "$work_dir" ] && echo "Dir: $work_dir"
        echo ""
        echo "Windows:"
        grep -E "new-session|new-window" "$proj_file" | sed "s/.*-n //;s/ .*//" | while read -r wname; do
            echo "  - $wname"
        done
    else
        echo "No .proj file — will create bare session"
    fi

  elif [[ "$line" == *"○ "* ]]; then
    # .proj file
    name=$(echo "$line" | sed "s/.*○ //")
    proj_file="$HOME/dotfiles/tmux/projects/${name}.proj"
    if [ -f "$proj_file" ]; then
        work_dir=$(grep "cd " "$proj_file" | head -1 | sed "s/.*cd //;s/'"'"'.*//" | xargs)
        [ -n "$work_dir" ] && echo "Dir: $work_dir" && echo ""
        echo "Windows:"
        grep -E "new-session|new-window" "$proj_file" | sed "s/.*-n //;s/ .*//" | while read -r wname; do
            echo "  - $wname"
        done
    else
        echo "New session from: ${name}.proj"
    fi

  elif [[ "$line" == *"+ "* ]]; then
    echo "Launch interactive project generator"
    echo "Creates a new .proj file in ~/dotfiles/tmux/projects/"

  elif [[ "$line" == *"⚠"* ]]; then
    echo "This will terminate all tmux sessions"

  else
    echo ""
  fi
'

# =============================================================================
# Run fzf
# =============================================================================

fzf_output=$(echo "$all_options" | fzf \
  --prompt="Session (<C-d> kill, <C-x> pin): " \
  --height=100% \
  --layout=reverse \
  --border \
  --preview="$preview_cmd" \
  --preview-window=right:40% \
  --expect=ctrl-d,ctrl-x)

# Parse output: first line is key (if --expect matched), rest is selection
key=$(echo "$fzf_output" | head -1)
selected=$(echo "$fzf_output" | tail -n +2)

if [[ -z "$selected" ]]; then
    exit 0
fi

# Ignore section headers
if [[ "$selected" == "━━"* ]]; then
    exit 0
fi

# =============================================================================
# Handle Ctrl-x (toggle pin)
# =============================================================================

if [[ "$key" == "ctrl-x" ]]; then
    # Only allow pinning active sessions (● or 📌)
    if [[ "$selected" == *"● "* ]] || [[ "$selected" == *"${PIN_ICON}"* ]]; then
        pin_target=$(extract_session_name "$selected")
        toggle_pin "$pin_target"
    fi
    # Re-run the script to refresh the menu
    exec bash "$SCRIPT_PATH"
fi

# =============================================================================
# Handle Ctrl-d (kill session)
# =============================================================================

if [[ "$key" == "ctrl-d" ]]; then
    # Only allow killing active sessions (● or 📌)
    if [[ "$selected" != *"● "* ]] && [[ "$selected" != *"${PIN_ICON}"* ]]; then
        exec bash "$SCRIPT_PATH"
    fi

    # Extract session name (strip icon and uptime)
    session_name=$(extract_session_name "$selected")

    # Count sessions
    session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$session_count" -eq 1 ]]; then
        # Last session - confirm kill server
        confirm=$(printf "Yes\nNo" | fzf --prompt="Last session - kill server? " --height=20% --layout=reverse --border)
        if [[ "$confirm" == "Yes" ]]; then
            tmux kill-server
            exit 0
        fi
    else
        # Multiple sessions - confirm kill and switch to another
        confirm=$(printf "Yes\nNo" | fzf --prompt="Kill session '$session_name'? " --height=20% --layout=reverse --border)
        if [[ "$confirm" == "Yes" ]]; then
            # Find next session (most recent, excluding the one being deleted)
            next_session=$(tmux list-sessions -F "#{session_last_attached}:#{session_name}" 2>/dev/null \
                | grep -v ":${session_name}$" \
                | sort -rn \
                | head -1 \
                | cut -d: -f2)

            # Switch to next session first (if we're in tmux and deleting current)
            current_session=$(tmux display-message -p '#S' 2>/dev/null)
            if [[ -n "$TMUX" && "$current_session" == "$session_name" && -n "$next_session" ]]; then
                tmux switch-client -t "$next_session"
            fi

            # Kill the session
            tmux kill-session -t "$session_name"
        fi
    fi
    # Re-launch picker (session list is now updated)
    exec bash "$SCRIPT_PATH"
fi

# =============================================================================
# Handle session selection (Enter)
# =============================================================================

if [[ "$selected" == *"⚠"* ]]; then
    # Kill tmux server with confirmation
    confirm=$(printf "Yes\nNo" | fzf --prompt="Kill tmux server? " --height=20% --layout=reverse --border)

    if [[ "$confirm" == "Yes" ]]; then
        tmux kill-server
        echo "Tmux server killed"
    fi
    exit 0

elif [[ "$selected" == *"+ "* ]]; then
    # Launch project generator
    bash "$HOME/dotfiles/tmux/scripts/create-project.sh"
    exit 0

elif [[ "$selected" == *"● "* ]] || [[ "$selected" == *"${PIN_ICON}"* ]]; then
    # Switching to existing active session (regular or pinned)
    session_name=$(extract_session_name "$selected")

    if [[ -n "$TMUX" ]]; then
        current_session=$(tmux display-message -p '#S')
        if [[ "$current_session" == "$session_name" ]]; then
            exit 0
        fi
        log_session_access "$session_name"
        tmux switch-client -t "$session_name"
    else
        log_session_access "$session_name"
        tmux attach-session -t "$session_name"
    fi

elif [[ "$selected" == *"◆ "* ]]; then
    # Recent inactive session — recreate from .proj or create bare
    session_name=$(extract_session_name "$selected")

    project_file=$(find_proj_file "$session_name")

    if [[ -n "$project_file" ]]; then
        launch_proj_file "$project_file" "$session_name"
    else
        # Create bare session
        log_session_access "$session_name"
        if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$session_name"
            tmux switch-client -t "$session_name"
        else
            tmux new-session -s "$session_name"
        fi
    fi

else
    # Creating new session from project file (○ section)
    session_name=$(echo "$selected" | sed 's/.*○ //')

    project_file=$(find_proj_file "$session_name")

    if [[ -n "$project_file" ]]; then
        launch_proj_file "$project_file" "$session_name"
    else
        # Fallback: create basic session
        project_path=""

        # Search for directory matching session name in known paths
        for dir in "${POSSIBLE_PROJECT_DIRS[@]}"; do
            if [[ -d "$dir/$session_name" ]]; then
                project_path="$dir/$session_name"
                break
            fi
        done

        # Final fallback to current directory
        if [[ -z "$project_path" ]]; then
            project_path=$(pwd)
        fi

        # Create new session
        log_session_access "$session_name"
        if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$session_name" -c "$project_path"
            tmux switch-client -t "$session_name"
        else
            tmux new-session -s "$session_name" -c "$project_path"
        fi
    fi
fi
