#!/usr/bin/env bash

# Smart tmux session picker that works in both terminal and tmux contexts
# Usage: 
#   - From terminal (C-s): Run with fzf directly 
#   - From tmux (C-a s): Run in popup (handled by tmux config)

# Get list of existing sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

# Possible directories to search for .proj files (auto-detected)
POSSIBLE_PROJECT_DIRS=(
    "$HOME/dotfiles/tmux/projects"
    "$HOME/dotfiles"
    "$HOME/projects"
    "$HOME/dev"
    "$HOME/code"
    "$HOME/work"
)

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

# Build formatted list with sections
all_options=""

# Active Sessions section
if [[ -n "$sessions" ]]; then
    all_options="━━ Active Sessions ━━"$'\n'
    all_options+=$(echo "$sessions" | sed 's/^/  ● /')
fi

# Create New Session section
if [[ -n "$project_files" ]]; then
    project_names=$(echo "$project_files" | xargs -I {} basename {} .proj | sed 's/^/  ○ /')
    if [[ -n "$all_options" ]]; then
        all_options+=$'\n'$'\n'"━━ Create New Session ━━"$'\n'"$project_names"
    else
        all_options="━━ Create New Session ━━"$'\n'"$project_names"
    fi
fi

# Kill server option
if [[ -n "$all_options" ]]; then
    all_options+=$'\n'$'\n'"━━━━━━━━━━━━━━━━━━━━━━"$'\n'"  ⚠ Kill tmux server"
else
    all_options="  ⚠ Kill tmux server"
fi

if [[ -z "$all_options" ]]; then
    echo "No sessions or project directories found"
    exit 1
fi

# Preview command for fzf
preview_cmd='
  line={}
  if [[ "$line" == *"● "* ]]; then
    session=$(echo "$line" | sed "s/.*● //")
    tmux list-windows -t "$session" -F "  #{window_index}: #{window_name} (#{pane_current_command})"
  elif [[ "$line" == *"○ "* ]]; then
    name=$(echo "$line" | sed "s/.*○ //")
    echo "New session from: ${name}.proj"
  elif [[ "$line" == *"⚠"* ]]; then
    echo "⚠ This will terminate all tmux sessions"
  else
    echo ""
  fi
'

# Use fzf with preview and ctrl-d to kill session
fzf_output=$(echo "$all_options" | fzf \
  --prompt="Choose session (<C-d> to kill): " \
  --height=100% \
  --layout=reverse \
  --border \
  --preview="$preview_cmd" \
  --preview-window=right:40% \
  --expect=ctrl-d)

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

# Extract the actual name (remove icon prefix)
session_name=$(echo "$selected" | sed 's/.*[●○⚠] //')

# Handle ctrl-d (kill session)
if [[ "$key" == "ctrl-d" ]]; then
    # Only allow killing active sessions (●)
    if [[ "$selected" != *"● "* ]]; then
        exit 0
    fi

    # Count sessions
    session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$session_count" -eq 1 ]]; then
        # Last session - confirm kill server
        confirm=$(printf "Yes\nNo" | fzf --prompt="Last session - kill server? " --height=20% --layout=reverse --border)
        if [[ "$confirm" == "Yes" ]]; then
            tmux kill-server
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
    exit 0
fi

# Handle session switching logic
if [[ "$selected" == *"⚠"* ]]; then
    # Kill tmux server with confirmation
    confirm=$(printf "Yes\nNo" | fzf --prompt="Kill tmux server? " --height=20% --layout=reverse --border)

    if [[ "$confirm" == "Yes" ]]; then
        tmux kill-server
        echo "Tmux server killed"
    fi
    exit 0
elif [[ "$selected" == *"● "* ]]; then
    # Switching to existing session
    if [[ -n "$TMUX" ]]; then
        # Inside tmux - check if already in selected session
        current_session=$(tmux display-message -p '#S')
        if [[ "$current_session" == "$session_name" ]]; then
            # Already in selected session, just exit
            exit 0
        fi
        # Different session - detach current and switch
        tmux switch-client -t "$session_name"
    else
        # Outside tmux - just attach
        tmux attach-session -t "$session_name"
    fi
else
    # Creating new session from project file
    # Search for .proj file in all possible directories
    project_file=""
    for dir in "${POSSIBLE_PROJECT_DIRS[@]}"; do
        found=$(find "$dir" -maxdepth 3 -name "${session_name}.proj" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            project_file="$found"
            break
        fi
    done

    if [[ -f "$project_file" ]]; then
        # Make sure the project file is executable
        chmod +x "$project_file"

        if [[ -n "$TMUX" ]]; then
            # Inside tmux - parse target session and switch to it
            target_session=$(grep -E "attach.*-t" "$project_file" | sed 's/.*-t //' | head -1)

            # Validate target_session was parsed
            if [[ -z "$target_session" ]]; then
                echo "Error: Could not parse session name from $project_file"
                echo "Ensure the .proj file contains: tmux attach -t <session_name>"
                read -p "Press Enter to continue..."
                exit 1
            fi

            # Create session if it doesn't exist
            if ! tmux has-session -t "$target_session" 2>/dev/null; then
                bash "$project_file" >/dev/null 2>&1 &
                sleep 0.5

                # Verify session was created
                if ! tmux has-session -t "$target_session" 2>/dev/null; then
                    echo "Error: Failed to create session '$target_session'"
                    echo "Check $project_file for errors"
                    read -p "Press Enter to continue..."
                    exit 1
                fi
            fi

            # Switch to the session
            tmux switch-client -t "$target_session"
        else
            # Outside tmux - just run project
            "$project_file"
        fi
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
        if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$session_name" -c "$project_path"
            tmux switch-client -t "$session_name"
        else
            tmux new-session -s "$session_name" -c "$project_path"
        fi
    fi
fi