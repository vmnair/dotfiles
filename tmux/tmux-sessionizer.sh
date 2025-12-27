#!/usr/bin/env bash

# Tmux session picker with fzf
# Usage: Run from within tmux to fuzzy find and switch sessions

# Get list of existing sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

# Store all tmux projects in dotfiles/tmux/projects with *proj extension.

if [[ -d "$HOME/dotfiles/tmux/projects" ]]; then
    project_files=$(find "$HOME/dotfiles/tmux/projects" -mindepth 1 -maxdepth 1 -type f -name "*.proj")
fi
# Combine sessions and project directories
all_options=""
if [[ -n "$sessions" ]]; then
    # Mark existing sessions with a prefix
    all_options=$(echo "$sessions" | sed 's/^/[ACTIVE] /')
fi

if [[ -n "$project_files" ]]; then
    # Add project files (strip .proj extension)
    project_names=$(echo "$project_files" | xargs -I {} basename {} .proj | sed 's/^/[NEW] /')
    if [[ -n "$all_options" ]]; then
        all_options="$all_options"$'\n'"$project_names"
    else
        all_options="$project_names"
    fi
fi

if [[ -z "$all_options" ]]; then
    echo "No sessions or project directories found"
    exit 1
fi

# Use fzf to select
selected=$(echo "$all_options" | fzf --prompt="Select tmux session: " --height=40% --layout=reverse --border)

if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract the actual name
session_name=$(echo "$selected" | sed 's/^\[.*\] //')

# Check if it's an existing session or new project
if [[ "$selected" == "[ACTIVE]"* ]]; then
    # Switch to existing session
    confirm=$(printf "Yes\nNo" | fzf --prompt="Kill tmux server?" --height=20% -- layout=reverse, --border)
fi
else
    # Execute project file
    project_file="$HOME/dotfiles/tmux/projects/${session_name}.proj"
    
    if [[ -f "$project_file" ]]; then
        # Make sure the project file is executable
        chmod +x "$project_file"
        
        # If we're in tmux, ask what to do with current session
        if [[ -n "$TMUX" ]]; then
            action=$(printf "switch\nkill-current\ndetach" | fzf --prompt="Action for current session: " --height=20% --layout=reverse --border)
            case "$action" in
                "switch")
                    # Execute the project file (it will create and attach)
                    "$project_file"
                    ;;
                "kill-current")
                    current_session=$(tmux display-message -p '#S')
                    "$project_file"
                    tmux kill-session -t "$current_session" 2>/dev/null || true
                    ;;
                "detach")
                    tmux detach-client
                    "$project_file"
                    ;;
                *)
                    exit 0
                    ;;
            esac
        else
            # Execute the project file
            "$project_file"
        fi
    else
        # Fallback: create basic session
        project_path=""
        
        # Find the full path
        if [[ -d "$HOME/projects/$session_name" ]]; then
            project_path="$HOME/projects/$session_name"
        elif [[ -d "$HOME/dev/$session_name" ]]; then
            project_path="$HOME/dev/$session_name"
        elif [[ "$session_name" == "dotfiles" ]]; then
            project_path="$HOME/dotfiles"
        else
            # Fallback to current directory
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
