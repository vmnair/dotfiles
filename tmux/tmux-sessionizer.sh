#!/usr/bin/env bash

# Tmux session picker with fzf
# Usage: Run from within tmux to fuzzy find and switch sessions

# Get list of existing sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

# Store all tmux projects in dotfiles/tmux/projects with *proj extension.
project_dirs=""

if [[ -d "$HOME/dotfiles/tmux/projects" ]]; then
    project_files=$(find "$HOME/dotfiles/tmux/projects" -mindepth 1 -maxdepth 1 -type f -name "*.proj")
fi
# Combine sessions and project directories
all_options=""
if [[ -n "$sessions" ]]; then
    # Mark existing sessions with a prefix
    all_options=$(echo "$sessions" | sed 's/^/[ACTIVE] /')
fi

if [[ -n "$project_dirs" ]]; then
    # Add project directories
    project_names=$(echo "$project_dirs" | xargs -I {} basename {} | sed 's/^/[NEW] /')
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
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
else
    # Create new session from project directory
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
