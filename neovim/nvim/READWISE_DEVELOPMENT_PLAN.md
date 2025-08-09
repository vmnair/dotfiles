# Readwise Neovim Integration - Complete Learning & Development Plan

## Table of Contents
1. [Project Overview](#project-overview)
2. [Learning Prerequisites](#learning-prerequisites)
3. [Phase 1: Understanding the Foundation](#phase-1-understanding-the-foundation)
4. [Phase 2: Single File Development (7-Day Plan)](#phase-2-single-file-development-7-day-plan)
5. [Phase 3: Plugin Conversion Guide](#phase-3-plugin-conversion-guide)
6. [Appendices](#appendices)

---

## Project Overview

### What We're Building
A Neovim integration for accessing Readwise highlights and books directly from your editor, following your established patterns with zk and todo_manager.

### Goals
- **Personal Use**: Seamlessly integrate Readwise with your existing workflow
- **Learning**: Understand Lua programming and Neovim plugin development
- **Future Publishing**: Structure for easy conversion to a community plugin

### Integration Points
- **ZK Notes**: Create notes from highlights
- **Todo Manager**: Convert highlights to todos
- **FZF-lua**: Consistent picker interface
- **Dropbox Sync**: Store cached data with your existing setup

---

## Learning Prerequisites

### Lua Concepts You'll Learn
1. **Tables** - Lua's primary data structure (like arrays + objects)
2. **Functions** - First-class functions, closures, callbacks
3. **Modules** - Creating and requiring modules
4. **Metatables** - Advanced table behavior (optional advanced topic)
5. **Error Handling** - pcall, xpcall, error management

### Neovim Concepts You'll Learn
1. **vim.api** - Core Neovim API functions
2. **Autocommands** - Event-driven programming
3. **User Commands** - Creating custom commands
4. **Keymaps** - Setting up key bindings
5. **Floating Windows** - Creating popup interfaces

### HTTP/API Concepts
1. **REST APIs** - Understanding HTTP requests
2. **Authentication** - API tokens and headers
3. **JSON Parsing** - Working with API responses
4. **Error Handling** - Network and API errors

---

## Phase 1: Understanding the Foundation

### 1.1 Readwise API Overview

**What is Readwise?**
- Service for collecting and reviewing highlights from books, articles, tweets
- Provides REST API for accessing your data
- Rate-limited: 240 requests/minute (20 for lists)

**Key Endpoints We'll Use:**
```
GET /api/v2/export/          # Get all highlights
GET /api/v2/books/           # Get books list
GET /api/v2/highlights/      # Get highlights
POST /api/v2/highlights/     # Create highlights
```

**Authentication:**
- Token-based (Bearer token in headers)
- Need to store securely (not in config files)

### 1.2 Your Existing Patterns Analysis

**From your todo_manager.lua:**
```lua
-- Configuration at top
M.config = {
    todo_dir = "path",
    categories = { "Medicine", "OMS", "Personal" },
    -- ... other settings
}

-- Utility functions (local)
local function get_current_date() end

-- Public API functions
function M.add_todo() end
function M.list_todos() end
```

**From your zk.lua:**
```lua
-- FZF-lua integration pattern
require("fzf-lua").fzf_exec(items, {
    prompt = "ZK Aliases> ",
    actions = {
        ["default"] = function(selected, opts)
            -- Handle selection
        end,
    },
})
```

---

## Phase 2: Single File Development (7-Day Plan)

### Day 1: Foundation & Configuration
**Learning Focus:** Lua modules, configuration patterns, basic setup

**What We'll Build:**
```lua
-- lua/vinod/readwise.lua structure
local M = {}

M.config = {
    -- API Configuration  
    api_token = nil,
    base_url = "https://readwise.io/api/v2",
    
    -- File Storage (following Dropbox pattern)
    cache_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/readwise/",
    
    -- Cache Duration (in seconds)
    cache_duration = {
        highlights = 24 * 60 * 60,  -- 24 hours
        books = 7 * 24 * 60 * 60,   -- 7 days  
    },
    
    -- UI Configuration (for FZF-lua integration)
    ui = {
        preview_width = 80,
        preview_height = 20,
        fzf_opts = {
            prompt = "Readwise> ",
            height = 0.8,
            width = 0.9,
        }
    },
    
    -- Integration with existing tools
    integration = {
        zk_enabled = true,      -- Create zk notes from highlights
        todo_enabled = true,    -- Create todos from highlights  
        auto_tag = true,        -- Auto-tag highlights by book/author
    },
    
    -- Debug mode
    debug = false,
}

-- Basic module setup
function M.setup(opts) end
```

**Key Learning Points:**
- How Lua modules work (`local M = {}`, `return M`)
- Table structures for configuration
- The `setup()` pattern used by Neovim plugins
- Cache duration strategies for API rate limiting
- Integration patterns with existing dotfiles tools

**Testing:** Basic module loading and configuration

**Additional Features Planned:**
- Manual refresh commands (`:ReadwiseRefresh`) for active reading sessions
- Configurable cache durations for different usage patterns
- Smart detection of reading/highlighting activity

---

### Day 2: API Client Implementation
**Learning Focus:** HTTP requests, JSON parsing, error handling

**What We'll Build:**
```lua
-- API client functions
local function make_request(endpoint, params) end
local function get_highlights() end  
local function get_books() end
```

**Key Learning Points:**
- Using `vim.fn.system()` or `curl` for HTTP requests
- JSON parsing with `vim.json.decode()`
- Error handling with `pcall()`
- Secure token storage

**Testing:** Successfully fetch data from Readwise API

---

### Day 3: Data Processing & Storage
**Learning Focus:** File I/O, data transformation, caching

**What We'll Build:**
```lua
-- Data processing
local function parse_highlights(raw_data) end
local function cache_data(data, filename) end
local function load_cached_data(filename) end
```

**Key Learning Points:**
- File operations (`io.open`, `file:read`, `file:write`)
- Data transformation and filtering
- Caching strategies for API rate limiting

**Testing:** Data persistence and retrieval

---

### Day 4: Basic UI with FZF-lua
**Learning Focus:** FZF-lua integration, picker interfaces

**What We'll Build:**
```lua
-- UI functions
function M.browse_books() end
function M.browse_highlights() end
local function show_highlight_picker() end
```

**Key Learning Points:**
- FZF-lua picker configuration
- Action handlers for selections
- Display formatting for readability

**Testing:** Interactive book and highlight browsing

---

### Day 5: Advanced UI Features
**Learning Focus:** Floating windows, preview functionality, advanced FZF features

**What We'll Build:**
```lua
-- Advanced UI
local function create_preview_window() end
local function show_highlight_detail() end
function M.search_highlights() end
```

**Key Learning Points:**
- Creating floating windows with `vim.api.nvim_open_win()`
- Preview functionality in pickers
- Search and filtering capabilities

**Testing:** Rich preview and search experience

---

### Day 6: Integration with ZK and Todo Manager
**Learning Focus:** Cross-module communication, your existing APIs

**What We'll Build:**
```lua
-- Integration functions
function M.create_zk_note_from_highlight() end
function M.create_todo_from_highlight() end
local function integrate_with_existing_tools() end
```

**Key Learning Points:**
- Requiring and using your existing modules
- Passing data between systems
- Maintaining consistency in user experience

**Testing:** End-to-end workflow from highlight to note/todo

---

### Day 7: Polish, Keymaps, and Help System
**Learning Focus:** User commands, keymaps, documentation

**What We'll Build:**
```lua
-- Commands and keymaps
local function setup_commands() end
local function setup_keymaps() end
function M.show_help() end
```

**Key Learning Points:**
- Creating user commands with `vim.api.nvim_create_user_command()`
- Setting up keymaps following your patterns
- Help system with floating windows (like your zk help)

**Testing:** Complete user experience with help and shortcuts

---

## Phase 3: Plugin Conversion Guide

### 3.1 Understanding Neovim Plugin Structure

**Standard Plugin Layout:**
```
readwise.nvim/
├── plugin/           # Auto-loaded files
│   └── readwise.lua  # Commands, keymaps, autocommands
├── lua/
│   └── readwise/
│       ├── init.lua  # Main module
│       ├── api.lua   # API client
│       ├── ui.lua    # User interface
│       └── utils.lua # Utilities
├── doc/
│   └── readwise.txt  # Help documentation
└── README.md
```

**Key Differences from Single File:**
- **plugin/** directory: Auto-loaded when Neovim starts
- **Modular structure**: Separate concerns into multiple files
- **Documentation**: Proper vim help files
- **Public API**: Clean interface for users

### 3.2 Migration Steps

**Step 1: Extract Modules**
```lua
-- From single file sections to separate files
-- Configuration -> lua/readwise/config.lua
-- API functions -> lua/readwise/api.lua
-- UI functions -> lua/readwise/ui.lua
-- Utilities -> lua/readwise/utils.lua
```

**Step 2: Create Plugin Loader**
```lua
-- plugin/readwise.lua
if vim.g.loaded_readwise then
  return
end
vim.g.loaded_readwise = 1

-- Set up commands and keymaps
-- (Commands that users can call directly)
```

**Step 3: Public API Design**
```lua
-- lua/readwise/init.lua
-- Clean interface for users
local M = {}

function M.setup(opts) end
function M.browse_highlights() end
function M.search(query) end

return M
```

### 3.3 Publishing Preparation

**Documentation:**
- README.md with installation and usage
- vim help files (doc/readwise.txt)
- Code comments and examples

**Testing:**
- Multiple Neovim versions
- Different operating systems
- Error scenarios and edge cases

**Repository Setup:**
- Git repository with proper .gitignore
- Release tags and changelog
- Issue templates and contributing guidelines

---

## Appendices

### Appendix A: Lua Quick Reference

**Tables (Lua's primary data structure):**
```lua
-- Array-like
local list = {"a", "b", "c"}
print(list[1]) -- "a" (1-indexed!)

-- Object-like  
local obj = {
    name = "John",
    age = 30,
    greet = function(self)
        print("Hello, " .. self.name)
    end
}
obj:greet() -- "Hello, John"
```

**Functions:**
```lua
-- Basic function
local function add(a, b)
    return a + b
end

-- Function as value
local operations = {
    add = function(a, b) return a + b end,
    multiply = function(a, b) return a * b end
}

-- Callback pattern
local function process_data(data, callback)
    local result = do_something(data)
    callback(result)
end
```

**Modules:**
```lua
-- Creating a module
local M = {}

function M.public_function()
    return "accessible from outside"
end

local function private_function()
    return "only accessible within this file"
end

return M
```

### Appendix B: Common Neovim API Functions

**Buffer Operations:**
```lua
-- Get current buffer
local buf = vim.api.nvim_get_current_buf()

-- Read lines
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

-- Write lines
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"new content"})
```

**Window Operations:**
```lua
-- Create floating window
local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = 50,
    height = 20,
    col = 10,
    row = 10,
    style = 'minimal',
    border = 'rounded'
})
```

**User Commands:**
```lua
vim.api.nvim_create_user_command('MyCommand', function()
    print("Command executed!")
end, {
    desc = "Description of the command"
})
```

### Appendix C: Debugging Tips

**Print Debugging:**
```lua
-- Simple print
print(vim.inspect(some_table))

-- Conditional printing
local function debug_print(msg)
    if M.config.debug then
        print("[Readwise] " .. msg)
    end
end
```

**Error Handling:**
```lua
local success, result = pcall(risky_function)
if not success then
    vim.notify("Error: " .. result, vim.log.levels.ERROR)
    return
end
```

**Testing Functions:**
```lua
-- Test individual functions
function M._test_api_call()
    local result = get_highlights()
    print(vim.inspect(result))
end
```

---

## Progress Status

### ✅ **COMPLETED: Day 1 - Foundation & Configuration**
**Date Completed**: 2025-08-09

**What We Built:**
- ✅ Basic Lua module structure in `lua/vinod/readwise.lua`
- ✅ Complete configuration system with all sections:
  - API settings (token, base_url) 
  - File storage (Dropbox cache directory)
  - Cache duration strategies (24h highlights, 7d books)
  - UI preferences (FZF-lua integration)
  - Integration flags (zk, todo_manager, auto-tagging)
- ✅ Setup function with option merging, directory creation, validation
- ✅ Full testing verified - all functionality working

**Key Learning Accomplished:**
- Lua module pattern (`local M = {}`, `return M`)
- Configuration table structures and nesting
- The `setup()` pattern used by Neovim plugins
- `vim.tbl_deep_extend()` for configuration merging
- `nvim --headless -c` debugging technique
- Cache duration strategies for API rate limiting

**Development Method Established:**
- Manual code entry by user (better learning)
- Claude explains concepts first, then user types code
- Claude verifies with headless testing
- Documentation updated as we modify plans

**Manual Refresh Feature Added:**
- Discussed need for `:ReadwiseRefresh` commands for active reading sessions
- Will implement in Day 2 API client functions

### 🔄 **NEXT: Day 2 - API Client Implementation**
**Learning Focus**: HTTP requests, JSON parsing, error handling, manual refresh

**Ready to implement:**
- API client functions for Readwise HTTP requests
- Authentication handling with secure token storage  
- JSON parsing with `vim.json.decode()`
- Error handling with `pcall()`
- Manual refresh commands for active reading workflow

## Next Steps

1. **Continue with Day 2** - API Client Implementation
2. **Maintain learning method** - Claude explains, user types, Claude verifies
3. **Keep updating docs** - Document changes and discoveries as we go
4. **Test frequently** - Use headless mode debugging for reliable testing

**Current Status**: Day 1 complete, ready to start Day 2 API implementation.