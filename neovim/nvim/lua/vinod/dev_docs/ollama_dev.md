# Ollama Integration Plan for Neovim

## ⚠️ CURRENT SESSION STATE - NEOVIM FROZEN ⚠️

### Session Summary (2025-11-02) - OllamaUpdate Plugin Fix (IN PROGRESS)

**CRITICAL: Neovim is currently FROZEN due to synchronous API calls blocking the main thread!**

#### Problem Discovered

**Original Issue - Model Name Parsing:**
- User ran `:OllamaUpdate` and got errors like "Could not fetch remote digest for model e59b580dfce7"
- **Root Cause**: The regex pattern in `get_local_models()` was matching the **ID column** (SHA hashes) instead of the **NAME column**
- **Why**: Pattern `([%w%-%._]+)%s+[%d%.]+` expected "name number letters", but `ollama list` outputs "name ID size modified"
- **Fix Applied**: Changed to line-by-line parsing using `^(%S+)` to capture first word (model name)

**Second Issue - No Remote Digest Support:**
- After fixing model names, still got "Could not fetch remote digest" errors
- **Root Cause**: `ollama show --remote` flag doesn't exist
- **Discovery**: The `ollama show` command:
  - Doesn't support `--remote` flag at all
  - Doesn't output digest information even with `--verbose`
  - Only shows architecture, parameters, capabilities

**Third Issue - API Approach:**
- Found that Ollama API exposes digests: `http://127.0.0.1:11434/api/tags`
- Implemented API-based approach using `curl` and JSON parsing
- Discovered API's `/api/pull` endpoint can check for updates

**CRITICAL ISSUE - Neovim Frozen:**
- When user ran `:OllamaUpdate` with the new API implementation, **Neovim completely froze**
- **Root Cause**: Synchronous `io.popen()` calls block Neovim's main thread
- **Why It Froze**:
  1. Plugin makes HTTP requests via `curl` using `io.popen()`
  2. `io.popen()` is synchronous - blocks until command completes
  3. With 14 models, that's 14+ sequential HTTP requests
  4. Each request takes time, potentially downloads models
  5. User can't type, can't interact with Neovim during this time
- **Current State**: User is in Ghostty terminal running Claude Code, which is running Neovim - can't force quit without losing Claude session

#### Current Broken Implementation

**File**: `/Users/vinodnair/dotfiles/neovim/nvim/lua/vinod/plugins/ollama.lua`

**Problem Code**:
```lua
-- This BLOCKS the main thread!
local function api_request(endpoint, data)
  local curl_cmd = string.format(
    'curl -s http://127.0.0.1:11434%s%s',
    endpoint,
    data and string.format(' -X POST -d \'%s\'', data) or ''
  )

  local handle = io.popen(curl_cmd, "r")  -- BLOCKS HERE
  if not handle then
    return nil
  end

  local result = handle:read("*a")  -- BLOCKS HERE
  handle:close()

  return vim.json.decode(result)
end
```

#### What Needs To Be Done Next (ASYNC VERSION)

**SOLUTION: Use plenary.nvim's async Job system**

**Implementation Plan**:

```lua
-- ollama.lua - Async version using plenary.job

local M = {}
local Job = require('plenary.job')

-- Async API request using plenary
-- @param endpoint string API endpoint
-- @param data table|nil Optional JSON data for POST
-- @param callback function Callback with (success, response)
local function api_request_async(endpoint, data, callback)
  local url = 'http://127.0.0.1:11434' .. endpoint
  local args = {'-s', url}

  if data then
    table.insert(args, '-X')
    table.insert(args, 'POST')
    table.insert(args, '-H')
    table.insert(args, 'Content-Type: application/json')
    table.insert(args, '-d')
    table.insert(args, vim.json.encode(data))
  end

  Job:new({
    command = 'curl',
    args = args,
    on_exit = function(j, return_val)
      if return_val == 0 then
        local result = table.concat(j:result(), '\n')
        local ok, decoded = pcall(vim.json.decode, result)
        if ok then
          callback(true, decoded)
        else
          callback(false, 'JSON parse error')
        end
      else
        callback(false, 'Request failed')
      end
    end,
  }):start()
end

-- Get local models asynchronously
local function get_local_models_async(callback)
  api_request_async('/api/tags', nil, function(success, response)
    if success and response.models then
      callback(response.models)
    else
      print('Failed to get models')
      callback({})
    end
  end)
end

-- Update a single model asynchronously
local function update_model_async(model_name, on_complete)
  print('Checking ' .. model_name .. '....')

  api_request_async('/api/pull', {
    name = model_name,
    stream = false
  }, function(success, response)
    if success and response.status == 'success' then
      print('  ✓ ' .. model_name .. ' - Up to date')
    else
      print('  ✗ ' .. model_name .. ' - Failed')
    end

    if on_complete then
      on_complete()
    end
  end)
end

-- Update all models with progress tracking
vim.api.nvim_create_user_command('OllamaUpdate', function()
  print('Fetching model list...')

  get_local_models_async(function(models)
    if #models == 0 then
      print('No models to update')
      return
    end

    print('Checking ' .. #models .. ' models...')
    local completed = 0

    for _, model in ipairs(models) do
      update_model_async(model.name, function()
        completed = completed + 1
        if completed == #models then
          print('✓ Done checking all models')
        end
      end)
    end
  end)
end, { desc = 'Update Ollama models if newer versions are available' })

return M
```

#### Key Benefits of Async Approach

1. **Non-blocking**: Neovim remains responsive during updates
2. **Progress feedback**: User can see which models are being checked
3. **Parallel requests**: Could potentially check multiple models simultaneously
4. **Better UX**: User can continue working while updates run

#### Testing Commands After Fix

```lua
-- After implementing async version:
:source lua/vinod/plugins/ollama.lua  -- Reload plugin
:OllamaUpdate  -- Should work without freezing
```

#### Alternative Approach (Simpler)

If plenary approach is too complex, could use `vim.fn.jobstart()`:

```lua
local function check_models_simple()
  vim.fn.jobstart({'ollama', 'pull', 'model-name'}, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        print('Model updated successfully')
      end
    end
  })
end
```

#### Resume Point After Force Quit

**When you come back**:

1. **Force quit Neovim/Ghostty if needed** (Command+Q or similar)
2. **Read this file** to understand where we left off
3. **Implement async version** using plenary.job (code above)
4. **Test with**:
   - `:OllamaUpdate` - Should work without freezing
   - Monitor output for proper model checking
   - Verify Neovim remains responsive

#### Files Modified This Session

- `/Users/vinodnair/dotfiles/neovim/nvim/lua/vinod/plugins/ollama.lua` - Currently broken with sync implementation

#### Key Insights

**Why the original approach failed**:
1. Parsing CLI output is fragile (column positions, formatting)
2. No `--remote` flag means can't check remote versions
3. Synchronous HTTP requests block Neovim's main thread

**Why async is necessary**:
- HTTP requests take time (network latency, downloads)
- Neovim's UI runs on single thread
- Blocking operations freeze the entire editor
- Modern Neovim development requires async for network operations

---

## Overview

A comprehensive ollama chat integration system for Neovim that provides seamless AI assistance within the development workflow. The system supports model management, persistent conversations, and unified behavior across tmux and terminal environments.

## System Architecture

### Core Design Principles

- **Independent Instances**: Each Neovim session manages its own ollama chat for context isolation
- **XDG Compliance**: Configuration and data stored in standard Linux directories
- **Unified Behavior**: Consistent experience across tmux and terminal environments
- **Buffer Integration**: Leverage Neovim's native buffer system for chat management
- **API-Only Buffer Context**: Use direct Ollama API for all buffer/selection operations (no terminal approach)

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

## Usage Workflows

**First-Time Setup**: `<leader>oo` → auto-prompt for model selection → save and start chat

**Daily Usage**: `<leader>oo` (start) → `<leader>ot` (toggle) → `<leader>os` (save conversations)

**Model Switching**: `<leader>om` → select model → graceful process restart

## Error Handling

- Model validation with fallback selection
- Service down detection with retry guidance
- Pane recovery on external kills
- Independent Neovim instances
- Progress feedback and silent loading

## Implementation Status: **BLOCKED - ASYNC REQUIRED** ⚠️

OllamaUpdate command implementation blocked by synchronous API calls freezing Neovim. Requires async implementation using plenary.job before proceeding.

_Last Updated: 2025-11-02_
