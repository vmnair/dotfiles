#!/bin/bash

# Unified AI Model Status Script
# Detects currently active AI model and provider (Online/Local) for tmux status bar
# Replaces separate get_copilot_model.sh and get_ollama_model.sh scripts

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Unified AI Model Status Script for tmux
# Uses tmux variables set by Neovim CopilotChat integration

# Function to detect CopilotChat active model and provider
detect_copilot_model() {
    local nvim_config="/Users/vinodnair/dotfiles/neovim/nvim/lua/vinod/plugins/copilot-chat.lua"
    
    if [ ! -f "$nvim_config" ] || [ ! -r "$nvim_config" ]; then
        echo "[AI: No Config]"
        return
    fi
    
    # Try to get active model from multiple sources
    local active_model=""
    
    # Method 1: Try to read from tmux environment variable (updated by Neovim)
    active_model=$(tmux showenv -g copilot_model 2>/dev/null | cut -d'=' -f2)
    
    # Method 2: Try to get current model from CopilotChat if tmux variable fails
    if [ -z "$active_model" ] && command -v nvim >/dev/null 2>&1; then
        local lua_script="$(dirname "$0")/get_current_ai_model.lua"
        if [ -f "$lua_script" ]; then
            active_model=$(timeout 2 nvim --headless -l "$lua_script" 2>/dev/null | tail -1 | tr -d '\n')
        fi
    fi
    
    # Fallback to default model from config if no active model found
    if [ -z "$active_model" ] || [ "$active_model" = "nil" ]; then
        # Updated pattern to match the current config structure
        active_model=$(grep -A 30 'CopilotChat.*setup' "$nvim_config" 2>/dev/null | grep -E '^\s*model\s*=' | head -1 | sed -E 's/.*model[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/' 2>/dev/null)
    fi
    
    if [ -z "$active_model" ]; then
        echo "[AI: Unknown]"
        return
    fi
    
    # Determine provider type based on model name patterns
    case "$active_model" in
        # OpenAI models (Online)
        gpt-3.5*|gpt-4*|text-*|davinci*|curie*|babbage*|ada*)
            echo "[AI: $active_model (Online)]"
            ;;
        # Anthropic models (Online)  
        claude-*|claude_*)
            echo "[AI: $active_model (Online)]"
            ;;
        # Common Ollama local models (Local)
        llama*|mistral*|codellama*|qwen*|phi*|gemma*|neural-chat*|orca*|vicuna*|alpaca*)
            echo "[AI: $active_model (Local)]"
            ;;
        # Generic patterns for local models
        *:*b|*:*B)  # Models with size indicators like "llama3.2:3b"
            echo "[AI: $active_model (Local)]"
            ;;
        # Default to Online for unknown models (safer assumption)
        *)
            echo "[AI: $active_model (Online)]"
            ;;
    esac
}

# Main execution
detect_copilot_model