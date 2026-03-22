#!/bin/bash

# Script to extract current Copilot model from Neovim config
# This reads the model from the CopilotChat configuration
# Only outputs when running in tmux to avoid errors in other contexts

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    # Not in tmux, exit silently
    exit 0
fi

NVIM_CONFIG_PATH="/Users/vinodnair/dotfiles/neovim/nvim/lua/vinod/plugins/copilot-chat.lua"

if [ -f "$NVIM_CONFIG_PATH" ] && [ -r "$NVIM_CONFIG_PATH" ]; then
    # Extract the model value from the opts section only (not embedding model)
    model=$(grep -A 20 '^\s*opts\s*=' "$NVIM_CONFIG_PATH" 2>/dev/null | grep -E '^\s*model\s*=' | head -1 | sed -E 's/.*model[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/' 2>/dev/null)
    
    if [ -n "$model" ]; then
        echo "[Copilot: $model]"
    else
        echo "[Copilot: Unknown]"
    fi
else
    # Config file not found or not readable, but we're in tmux, so show placeholder
    echo "[Copilot: No Config]"
fi