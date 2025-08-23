#!/usr/bin/env bash

# Smart tmux session picker that works in both terminal and tmux contexts
# Usage: 
#   - From terminal (C-s): Run with fzf directly 
#   - From tmux (C-a s): Run in popup (handled by tmux config)

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

if [[ -n "$project_files" ]]; then
    # Add project files (strip .proj extension)
    project_names=$(echo "$project_files" | xargs -I {} basename {} .proj | sed 's/^/[NEW] /')
    if [[ -n "$all_options" ]]; then
        all_options="$all_options"$'\n'"$project_names"
    else
        all_options="$project_names"
    fi
fi

# Add kill server option at the end
if [[ -n "$all_options" ]]; then
    all_options="$all_options"$'\n'"[KILL] Kill tmux server"
else
    all_options="[KILL] Kill tmux server"
fi

if [[ -z "$all_options" ]]; then
    echo "No sessions or project directories found"
    exit 1
fi

# Detect context and use appropriate fzf
if [[ -n "$TMUX" ]]; then
    # Inside tmux - use fzf directly (popup handled by tmux config)
    selected=$(echo "$all_options" | fzf --prompt="Select tmux session: " --height=40% --layout=reverse --border)
else
    # Outside tmux - use fzf in full terminal
    selected=$(echo "$all_options" | fzf --prompt="Select tmux session: " --height=50% --layout=reverse --border)
fi

if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract the actual name
session_name=$(echo "$selected" | sed 's/^\[.*\] //')

# Handle session switching logic
if [[ "$selected" == "[KILL]"* ]]; then
    # Kill tmux server with confirmation
    if [[ -n "$TMUX" ]]; then
        # Inside tmux - use fzf for confirmation in popup
        confirm=$(printf "Yes\nNo" | fzf --prompt="Kill tmux server? " --height=20% --layout=reverse --border)
    else
        # Outside tmux - use fzf in terminal
        confirm=$(printf "Yes\nNo" | fzf --prompt="Kill tmux server? " --height=20% --layout=reverse --border)
    fi
    
    if [[ "$confirm" == "Yes" ]]; then
        tmux kill-server
        echo "Tmux server killed"
    fi
    exit 0
elif [[ "$selected" == "[ACTIVE]"* ]]; then
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
    project_file="$HOME/dotfiles/tmux/projects/${session_name}.proj"
    
    if [[ -f "$project_file" ]]; then
        # Make sure the project file is executable
        chmod +x "$project_file"
        
        if [[ -n "$TMUX" ]]; then
            # Inside tmux - detach and run project
            tmux detach-client
            "$project_file"
        else
            # Outside tmux - just run project
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