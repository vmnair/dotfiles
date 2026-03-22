#!/bin/bash

# Script to extract current Ollama default model from config
# This reads the default model from the Ollama configuration
# Only outputs when running in tmux to avoid errors in other contexts

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    # Not in tmux, exit silently
    exit 0
fi

OLLAMA_CONFIG_PATH="/Users/vinodnair/.config/nvim/ollama_config.lua"

if [ -f "$OLLAMA_CONFIG_PATH" ] && [ -r "$OLLAMA_CONFIG_PATH" ]; then
    # Extract the default_model value from the config file
    model=$(grep -E '^\s*default_model\s*=' "$OLLAMA_CONFIG_PATH" 2>/dev/null | sed -E 's/.*default_model[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/' 2>/dev/null)
    
    if [ -n "$model" ]; then
        echo "[Ollama: $model]"
    else
        echo "[Ollama: Unknown]"
    fi
else
    # Config file not found or not readable, but we're in tmux, so show placeholder
    echo "[Ollama: No Config]"
fi