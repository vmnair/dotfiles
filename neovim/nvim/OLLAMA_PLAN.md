# Ollama Integration Plan for Neovim

## Overview

A comprehensive ollama chat integration system for Neovim that provides seamless AI assistance within the development workflow. The system supports model management, persistent conversations, and unified behavior across tmux and terminal environments.

### Documentation

Please note that this documentation need to be updated with each logic changes.
Just need to be succint and clean as changes are made and need to be kept
uptodate.

## System Architecture

### Core Design Principles

- **Independent Instances**: Each Neovim session manages its own ollama chat for context isolation
- **XDG Compliance**: Configuration and data stored in standard Linux directories
- **Unified Behavior**: Consistent experience across tmux and terminal environments
- **Buffer Integration**: Leverage Neovim's native buffer system for chat management

### Storage Structure

```
~/.config/nvim/ollama_config.lua          # Configuration (model, split preference)
~/.local/share/nvim/ollama/               # Data directory
├── chats/                                # Saved conversations
│   ├── session1_llama3.2-3b_20250123-143022.txt
│   └── debugging_codellama-7b_20250122-091534.txt
└── cleanup.log                           # Optional cleanup tracking
```

## Complete Keybinding Scheme

### Primary Operations

- `<leader>od` - Set/change default model (persistent)
- `<leader>oo` - Open chat with default model
- `<leader>om` - Switch model in existing chat (same UI as od)
- `<leader>ot` - Toggle chat pane visibility
- `<leader>oc` - Close chat session

### Layout Control

- `<leader>oh` - Force horizontal split (persistent preference)
- `<leader>ov` - Force vertical split (persistent preference)

### Session Management

- `<leader>os` - Save current chat with user-provided name
- `<leader>ol` - Load saved chat as new buffer
- `<leader>ox` - Clear all saved chats (with confirmation)

## Implementation Details

### Model Management

- **Validation**: Check model availability before starting chat using `ollama list`
- **Progress Feedback**: Use `vim.notify()` for status updates
- **Model Switching**: Kill current process, start new model gracefully
- **Error Recovery**: If default model unavailable, prompt for new selection

### Configuration System

- **Format**: Lua table stored in `~/.config/nvim/ollama_config.lua`
- **Structure**:
  ```lua
  return {
      default_model = "llama3.2:3b",
      split_preference = "horizontal", -- or "vertical"
      last_updated = "2025-01-23"
  }
  ```

### Chat Session Handling

- **Single Session**: One ollama chat per Neovim instance
- **State Preservation**: Remember pane ID and visibility across toggles
- **Process Management**: Track ollama process ID for clean shutdown
- **Split Behavior**: 50% splits, persistent horizontal/vertical preference

### Buffer Management Strategy

- **Active Chat**: Live terminal buffer with running ollama process
- **Saved Chats**: Separate read-only buffers with complete conversation history
- **Navigation**: Standard Vim commands (`:ls`, `:bN`, `Ctrl-6`)
- **Non-Destructive Loading**: `<leader>ol` opens new buffer, preserves active chat

### Storage & Persistence

- **Config Format**: Lua table with model and split preferences
- **Chat Format**: Complete buffer dump (terminal content with formatting)
- **Naming Convention**: `<user-name>_<model>_<timestamp>.txt`
- **Duplicate Handling**: Append to existing file for same name
- **Auto-Cleanup**: Remove chats older than 30 days on startup

### Environment Integration

- **Tmux Detection**: Use `$TMUX` environment variable
- **UI Selection**: Tmux popup vs terminal fzf based on environment
- **Split Management**: Unified 50% split behavior across environments
- **Process Lifecycle**: Natural cleanup when tmux sessions close

## User Flows

### First-Time Setup

1. User presses `<leader>oo` with no config
2. Auto-prompt: "No default model set. Please select one:"
3. Show model picker (context-aware UI)
4. Save selection and proceed with chat

### Daily Usage

1. `<leader>oo` - Start chat with default model
2. Work with AI assistance
3. `<leader>ot` - Hide chat when focusing on code
4. `<leader>ot` - Show chat when need assistance again
5. `<leader>os session-name` - Save important conversations

### Model Switching

1. `<leader>om` - Select new model
2. Current ollama process killed gracefully
3. New model starts with progress indication
4. Continue conversation with new model

## Error Handling & Edge Cases

- **Model Unavailable**: Show available models, prompt for selection
- **Ollama Service Down**: Clear error message with retry guidance
- **Pane Killed Externally**: Detect and recreate on next toggle
- **Multiple Instances**: Each Neovim session operates independently
- **Progress Indication**: Loading messages during model startup
- **Silent Operation**: System loads without verbose startup messages for clean UX

## Implementation Status

### Phase 1: Core Infrastructure ✅

- [x] Create core ollama manager module
- [x] Implement model discovery and validation
- [x] Build configuration system with Lua config files
- [x] Add basic chat startup functionality

### Phase 2: Keybinding Implementation ✅

- [x] Primary operations (od, oo, om, ot, oc)
- [x] Layout control (oh, ov) with persistence
- [x] Context-aware model selection UI (tmux popup vs fzf-lua vs fallback)

### Phase 3: Session Management ✅

- [x] Chat saving with buffer dump approach
- [x] Loading saved chats as separate buffers
- [x] Session management keybindings (os, ol, ox)
- [x] Auto-cleanup system (30-day retention)

### Phase 4: Polish & Integration ✅

- [x] Comprehensive error handling and edge cases
- [x] Progress feedback system with vim.notify()
- [x] Integration with existing Neovim configuration
- [x] Silent loading without verbose startup messages
- [x] Comprehensive help system with floating window dialog

## Outstanding Issues 🔧

### ✅ RESOLVED: Tmux Statusbar Not Updating When Switching Ollama Models

**Issue**: When using `<leader>om` to switch ollama models in Neovim, the tmux statusbar continued to show the old model name instead of updating to the new model.

**Root Cause**: The `switch_model()` function was not properly updating the persistent config file that the tmux statusbar script reads from.

**Solution Applied**: ✅ **RESOLVED**
- **File**: `ollama_chat.lua` (lines 229-231)  
- **Fix**: Added proper config loading/saving in `switch_model()` function:
  ```lua
  -- Update the persistent configuration with new model
  local config = ollama_manager.load_config() or {}
  config.default_model = selected_model
  ollama_manager.save_config(config)
  ```

**Status**: ✅ **CONFIRMED WORKING** - Tmux statusbar now updates correctly when switching models

### ✅ RESOLVED: "not a terminal" Error

**Status**: ✅ **RESOLVED** - C-s workflow working correctly

## Files Created

### Core Implementation ✅

- `lua/vinod/ollama_manager.lua` - Core functionality (model discovery, config management)
- `lua/vinod/ollama_ui.lua` - Context-aware model selection UI
- `lua/vinod/ollama_chat.lua` - Chat session management and control
- `lua/vinod/ollama_session.lua` - Chat saving/loading functionality
- `lua/vinod/config/ollama_commands.lua` - Commands and keybindings
- `init.lua` - Updated to load ollama commands

### Configuration (Auto-created)

- `~/.config/nvim/ollama_config.lua` - User configuration with model and split preferences

### Data Storage (Auto-created)

- `~/.local/share/nvim/ollama/chats/` - Saved chat conversations

## Available Commands

### User Commands

- `:OllamaOpen` - Open chat with default model
- `:OllamaSetDefault` - Set default model
- `:OllamaSwitch` - Switch model in current session
- `:OllamaToggle` - Toggle chat visibility
- `:OllamaClose` - Close chat session
- `:OllamaHorizontal` / `:OllamaVertical` - Set split preference
- `:OllamaSave [name]` - Save current chat
- `:OllamaLoad` - Load saved chat
- `:OllamaClear` - Clear all saved chats
- `:OllamaInfo` - Show model information
- `:OllamaHelp` - Show comprehensive help dialog

### Complete Keybinding Reference

| Keybinding   | Action       | Description                     |
| ------------ | ------------ | ------------------------------- |
| `<leader>od` | Set Default  | Set/change default model        |
| `<leader>oo` | Open Chat    | Open chat with default model    |
| `<leader>om` | Switch Model | Switch model in current session |
| `<leader>ot` | Toggle       | Show/hide chat pane             |
| `<leader>oc` | Close        | Close chat session              |
| `<leader>oH` | Horizontal   | Set horizontal split preference |
| `<leader>oV` | Vertical     | Set vertical split preference   |
| `<leader>ow` | Save         | Save current chat with name     |
| `<leader>ol` | Load         | Load saved chat                 |
| `<leader>ox` | Clear        | Clear all saved chats           |
| `<leader>oi` | Info         | Show model and session info     |
| `<leader>oh` | Help         | Show comprehensive help dialog  |
| `<leader>ob` | Buffer       | Send current buffer to Ollama   |
| `<leader>os` | Selection    | Send visual selection to Ollama |

---

_Last Updated: 2025-08-23_
_Implementation Status: **COMPLETE** ✅_

All planned functionality has been implemented and integrated into your Neovim configuration. The system is ready for use!
