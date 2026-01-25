#!/bin/bash

# Script to get git status for tmux status bar
# Shows: branch name, dirty indicator (*), ahead/behind counts
# Colors: yellow if dirty, red if behind, green if clean

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Get the current pane's working directory
pane_path=$(tmux display-message -p '#{pane_current_path}')

# Change to pane directory
cd "$pane_path" 2>/dev/null || exit 0

# Check if it's a git repo
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Get branch name (handle detached HEAD)
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

# Exit if we couldn't get branch
[ -z "$branch" ] && exit 0

# Truncate if longer than 20 chars
if [ ${#branch} -gt 20 ]; then
    branch="${branch:0:17}..."
fi

# Check for uncommitted changes (staged or unstaged)
dirty=""
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    dirty="*"
fi

# Check ahead/behind remote (with timeout for slow remotes)
ahead_behind=""
counts=$(timeout 1 git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
if [ -n "$counts" ]; then
    behind=$(echo "$counts" | cut -f1)
    ahead=$(echo "$counts" | cut -f2)
    [ "$ahead" -gt 0 ] 2>/dev/null && ahead_behind+="↑$ahead"
    [ "$behind" -gt 0 ] 2>/dev/null && ahead_behind+="↓$behind"
fi

# Determine icon color based on state (white=clean, yellow=dirty)
if [ -n "$dirty" ]; then
    icon_color="yellow"
else
    icon_color="white"
fi

# Output: colored icon, white branch name
echo "#[fg=$icon_color] #[fg=white]${branch}${dirty}${ahead_behind}"
