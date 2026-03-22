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
    # Single source of truth: tmux environment variable (updated by Neovim)
    local active_model
    active_model=$(tmux showenv -g copilot_model 2>/dev/null | cut -d'=' -f2)
    
    # If no model is set, fall back to default model (gpt-oss:20b)
    if [ -z "$active_model" ] || [ "$active_model" = "nil" ]; then
        active_model="gpt-oss:20b"
        # Set the tmux variable to persist the default
        tmux setenv -g copilot_model "$active_model" 2>/dev/null
    fi
    
    # Determine provider type based on model name patterns
    case "$active_model" in
        # OpenAI models (Online)
        gpt-3.5*|gpt-4*|text-*|davinci*|curie*|babbage*|ada*)
            echo "◉ $active_model (Online)"
            ;;
        # Anthropic models (Online)  
        claude-*|claude_*)
            echo "◉ $active_model (Online)"
            ;;
        # Common Ollama local models (Local)
        llama*|mistral*|codellama*|qwen*|phi*|gemma*|neural-chat*|orca*|vicuna*|alpaca*)
            echo "◉ $active_model (Local)"
            ;;
        # Generic patterns for local models
        *:*b|*:*B)  # Models with size indicators like "llama3.2:3b"
            echo "◉ $active_model (Local)"
            ;;
        # Default to Online for unknown models (safer assumption)
        *)
            echo "◉ $active_model (Online)"
            ;;
    esac
}

# Main execution
detect_copilot_model