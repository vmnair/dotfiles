# Readwise Neovim Integration - Development Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Learning Prerequisites](#learning-prerequisites)
3. [Phase 1: Understanding the Foundation](#phase-1-understanding-the-foundation)
4. [Phase 2: Single File Development (7-Day Plan)](#phase-2-single-file-development-7-day-plan)
5. [Phase 3: Plugin Conversion Guide](#phase-3-plugin-conversion-guide)
6. [Progress Status](#progress-status)
7. [Appendices](#appendices)

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
- **Portable Cache**: Store cached data with optional cloud sync

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

**Key Endpoints:**
```
GET /api/v2/export/          # Get all highlights (primary endpoint)
GET /api/v2/books/           # Get books list
POST /api/v2/highlights/     # Create highlights
```

**Authentication:**
- Token-based: `Authorization: Token YOUR_TOKEN_HERE`
- Get token from: https://readwise.io/access_token
- Store in environment variable `READWISE_TOKEN` or config

**Implementation Strategy:**
- Use `/api/v2/export/` as main endpoint (240 req/min limit)
- plenary.nvim for async HTTP requests (no blocking)
- Cache with configurable refresh (default: 4 hours for highlights)
- Portable default cache location: `~/.local/share/nvim/readwise/`

---

## Phase 2: Single File Development (7-Day Plan)

### Day 1: Foundation & Configuration
**What We'll Build:**
- Module structure (`local M = {}`, `return M`)
- Configuration system with sensible defaults
- `M.setup()` function for user customization
- Cache directory with automatic creation

**Key Learning:**
- Lua modules and tables
- Configuration patterns
- `vim.tbl_deep_extend()` for option merging

---

### Day 2: API Client Implementation
**What We'll Build:**
- Async API client using plenary.job
- Token authentication (environment + config fallback)
- JSON parsing and error handling
- Complete test coverage with mocks

**Key Learning:**
- Async patterns with callbacks
- plenary.job for non-blocking HTTP
- Test-driven development (TDD)

---

### Day 3: Data Processing & Storage
**What We'll Build:**
- `cache_data()` - Write JSON to disk with timestamp
- `load_cached_data()` - Read and validate cached JSON
- `is_cache_valid()` - Timestamp-based freshness check
- `M.get_highlights()` - Smart orchestration (cache OR fetch)

**Key Learning:**
- File I/O (`io.open`, `file:read`, `file:write`)
- Cache validation with Unix timestamps
- Orchestration patterns
- Async callback chains

---

### Day 4: Basic UI with FZF-lua
**What We'll Build:**
- `M.browse_highlights()` - Interactive picker
- `M.browse_books()` - Book selection interface
- Preview functionality
- Action handlers for selections

**Key Learning:**
- FZF-lua picker configuration
- Display formatting
- User interaction patterns

---

### Day 5: Advanced UI Features
**What We'll Build:**
- Floating windows for detailed views
- Search and filtering capabilities
- Preview enhancements
- Keyboard navigation

**Key Learning:**
- `vim.api.nvim_open_win()` for floating windows
- Advanced FZF-lua features
- UI polish and UX

---

### Day 6: Integration with ZK and Todo Manager
**What We'll Build:**
- `M.create_zk_note_from_highlight()` - ZK integration
- `M.create_todo_from_highlight()` - Todo integration
- Cross-module communication
- Data transformation for integrations

**Key Learning:**
- Requiring existing modules
- Data format conversion
- Workflow integration

---

### Day 7: Polish, Keymaps, and Help System
**What We'll Build:**
- User commands (`:Readwise*`)
- Key mappings
- Help system (floating window with keybinds)
- Documentation

**Key Learning:**
- `vim.api.nvim_create_user_command()`
- Keymap setup patterns
- In-editor help systems

---

## Phase 3: Plugin Conversion Guide

### Standard Plugin Layout
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

### Migration Steps
1. **Extract modules** - Separate concerns into focused files
2. **Create plugin loader** - Auto-load commands and setup
3. **Write documentation** - README and vim help files
4. **Test across platforms** - macOS and Linux compatibility

---

## Progress Status

### ✅ **Day 1: Foundation & Configuration** (Completed 2025-08-09)

**What We Built:**
- Complete Lua module structure
- Configuration system with all sections
- `M.setup()` with option merging and validation
- TDD framework with plenary.nvim

**Key Learning:**
- Lua module patterns
- Configuration tables and nesting
- `vim.tbl_deep_extend()` for merging
- Test framework setup

---

### ✅ **Day 2: API Client Implementation** (Completed 2025-09-28)

**What We Built:**
- `M.get_highlights_async()` - Async API client with plenary.job
- `get_api_token()` - Secure token management (env var + config fallback)
- Complete authentication system
- Comprehensive test coverage with mocks

**Key Learning:**
- plenary.job API and async patterns
- Callback patterns (`callback(data, nil)` vs `callback(nil, error)`)
- Test mocking for network isolation
- ~/.secrets file for secure token storage

**Final Status:** 3 tests passing (2 config + 1 async API)

---

### 🔄 **Day 3: Data Processing & Storage** (IN PROGRESS - Started 2025-10-05)

**Implementation Complete:**
- ✅ **Function 1**: `cache_data()` - Write JSON with timestamp metadata
- ✅ **Function 2**: `load_cached_data()` - Read and parse cached JSON
- ✅ **Function 3**: `is_cache_valid()` - Timestamp-based freshness validation
- ✅ **Function 4**: `M.get_highlights()` - Smart cache orchestration

**Test Status:** 11/11 passing ✅
```
✅ Configuration (2 tests)
✅ Async API (1 test)
✅ Cache I/O (2 tests)
✅ Cache Validation (4 tests)
✅ Smart Orchestration (2 tests) ← Latest
```

#### **Session 5 - First Orchestration Test** (2025-10-12)

**Major Accomplishments:**

**✅ Shell Debugging Skills Mastered**
- Grep pipelines: `./run_tests.sh 2>&1 | grep -A 10 "pattern"`
- Stream redirection: Understanding stdout (1) vs stderr (2)
- Verbose mode: `./run_tests.sh verbose` for detailed errors
- Stack trace reading: Bottom-to-top call chain analysis

**Common Grep Commands:**
```bash
# Show context
./run_tests.sh 2>&1 | grep -B 5 -A 10 "test name"

# Count matches
./run_tests.sh 2>&1 | grep -c "Success"

# Case-insensitive
./run_tests.sh 2>&1 | grep -i "error"
```

**✅ Async Test Pattern Debugging**

**Error 1 - Missing callback parameter:**
```lua
-- Wrong (treats async as sync)
local data, err = readwise.get_highlights()

-- Correct (async with callback)
readwise.get_highlights(function(data, err)
  callback_data = data
  completed = true
end, false)
```

**Error 2 - Data structure mismatch:**
- Problem: Double-wrapping data (test pre-wrapped, then cache_data() wrapped again)
- Solution: Pass raw API data to `cache_data()`, not pre-wrapped data
- Access pattern: `callback_data.data.text` (not `callback_data.text`)

**✅ Test Data Design Philosophy**
**Principle:** Only include what you're testing!

**Minimal (preferred for unit tests):**
```lua
local test_data = {
  text = "Cached highlights"  -- Just what you're asserting on
}
```

**Realistic (for integration tests):**
```lua
local test_data = {
  count = 2,
  results = {...},
  next = "url"
}
```

**✅ First Orchestration Test Complete**
- Test: "should return cached data when cache is fresh"
- Validates cache hit scenario (fast path, no API call)
- Confirms callback pattern and data structure correctness

**Debugging Workflow Mastered:**
1. Run `./run_tests.sh` → See which test failed
2. Run `./run_tests.sh verbose` → See exact error and line numbers
3. Read stack trace → Identify error location
4. Fix issue → Re-run tests
5. Iterate until green ✅

---

#### **Session 6 - Stale Cache Test** (2025-10-14)

**Major Accomplishments:**

**✅ Second Orchestration Test Complete**
- Test: "should fetch new data when cache is stale or missing"
- Validates cache expiration logic (slow path, API called)
- Creates cache with 5-hour-old timestamp (beyond 4-hour limit)
- Confirms API is called instead of using stale cache

**✅ Path Construction Debugging**

**The Bug: Filename Mismatch**
```lua
// Test created file at:
test_cache_dir = "/tmp/readwise_test_cache"      ← No trailing slash
cache_file = test_cache_dir .. "/highlights_cache.json"
// Result: /tmp/readwise_test_cache/highlights_cache.json

// But code looked for:
cache_dir .. filename = "/tmp/readwise_test_cache" .. "highlights_cache.json"
// Result: /tmp/readwise_test_cachehighlights_cache.json  ← Missing slash!
```

**The Fix:**
```lua
test_cache_dir = "/tmp/readwise_test_cache/"  ← Add trailing slash
cache_file = test_cache_dir .. "highlights_cache.json"  ← No extra slash
// Result: /tmp/readwise_test_cache/highlights_cache.json ✅
```

**Key Learning: File System Path Construction**
- Directory paths must have **consistent trailing slash handling**
- Either ALWAYS include trailing slash in directory vars
- Or NEVER add slash during concatenation
- Mixing approaches creates different file paths

**✅ Mock Verification Pattern**
```lua
-- Track if function was called
local api_was_called = false

-- Replace with mock
readwise.get_highlights_async = function(callback)
  api_was_called = true  -- Set flag
  callback({ text = "Fresh" }, nil)
end

-- Assert the flag
assert.is_true(api_was_called, "API should be called for stale cache")
```

This pattern verifies **control flow** (which code path executed), not just data.

**✅ Typo Debugging Experience**
- Fixed `file.close()` → `file:close()` (method call syntax)
- Fixed variable name: `original_get_highlights_sync` → `original_get_highlights_async`
- Fixed typo: `readwise.get_highlights_asyc` → `readwise.get_highlights_async`

**Code Location:** `tests/readwise_spec.lua` lines 286-346

---

### 🔄 **Day 3 Remaining Work: 3 More Orchestration Tests**

**Test Cases to Implement:**
1. ✅ **Cache hit (fresh)** - DONE! (Session 5)
2. ✅ **Stale cache** - DONE! (Session 6)
3. ⏭️ **Force refresh** - Should bypass cache when `force_refresh=true`
4. ⏭️ **API error handling** - Should propagate errors gracefully
5. ⏭️ **Cache save after fetch** - Should save fresh data to cache

**Expected Final Count:** 14 tests (11 existing + 3 new)

**Test Pattern:**
```lua
it("should [behavior]", function()
  -- Setup: Create test environment
  -- Execute: Call function with callback
  -- Wait: vim.wait() for async completion
  -- Assert: Verify callback data
  -- Cleanup: Delete test files
end)
```

---

### ⏭️ **Day 4: Basic UI with FZF-lua** (Not Started)
- Interactive pickers for highlights and books
- Preview functionality
- Action handlers

### ⏭️ **Day 5: Advanced UI Features** (Not Started)
- Floating windows for detailed views
- Search and filtering

### ⏭️ **Day 6: Integration with ZK and Todo Manager** (Not Started)
- Cross-module communication
- Workflow integration

### ⏭️ **Day 7: Polish, Keymaps, and Help System** (Not Started)
- User commands and keymaps
- Help system

---

## Appendices

### Appendix A: Lua Quick Reference

**Tables:**
```lua
-- Array-like (1-indexed!)
local list = {"a", "b", "c"}
print(list[1])  -- "a"

-- Object-like
local obj = {
  name = "John",
  greet = function(self)
    print("Hello, " .. self.name)
  end
}
obj:greet()  -- "Hello, John"
```

**Functions:**
```lua
-- Basic function
local function add(a, b)
  return a + b
end

-- Callback pattern
local function process_data(data, callback)
  local result = transform(data)
  callback(result)
end
```

**Modules:**
```lua
local M = {}

function M.public_function()
  return "accessible from outside"
end

local function private_function()
  return "only accessible within this file"
end

return M
```

---

### Appendix B: Common Neovim API Functions

**Buffer Operations:**
```lua
local buf = vim.api.nvim_get_current_buf()
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"new content"})
```

**Window Operations:**
```lua
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
end, { desc = "Description" })
```

---

### Appendix C: Debugging Tips

**Print Debugging:**
```lua
print(vim.inspect(some_table))

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

---

### Appendix D: Test Runner Usage

**Quick Reference:**
```bash
# Normal mode (clean output)
./run_tests.sh

# Verbose mode (see all details)
./run_tests.sh verbose

# Watch mode (auto-run on changes)
./run_tests.sh watch

# Help
./run_tests.sh help
```

**Debugging with Grep:**
```bash
# Show test failures with context
./run_tests.sh 2>&1 | grep -A 10 "Failed"

# Find specific test
./run_tests.sh verbose 2>&1 | grep -B 2 -A 15 "test name"

# Count successes
./run_tests.sh 2>&1 | grep -c "Success"
```

---

### Appendix E: Cache Architecture Decisions

**1. Cache Location:**
- **Default**: `vim.fn.stdpath("data") .. "/readwise/"` (portable)
  - macOS: `~/.local/share/nvim/readwise/`
  - Linux: `~/.local/share/nvim/readwise/`
- **Override**: Users can configure Dropbox, iCloud, or custom paths

**2. Cache Duration:**
- **Highlights**: 4 hours (fresh data, responsive to reading sessions)
- **Books**: 24 hours (rarely changes)
- **Rationale**: API limit is 240 req/min = 345,600/day. Even with 1-hour cache (24 refreshes/day), we use only 0.007% of daily capacity. **Network latency** (500ms-2s) is the real bottleneck, not API limits.

**3. Testing Approach:**
- **Day 1-2**: Strict TDD (write tests first)
- **Day 3**: Test-After (implement, understand, then test)
- **Rationale**: Focus on learning cache logic without test complexity overhead

---

### Appendix F: Development Method Reminders

**⚠️ IMPORTANT:**
- **Manual code entry**: User writes code manually for better learning
- **Claude's role**: Explain concepts, provide instructions, verify user's code
- **Process**: Claude explains → User codes → Claude verifies
- **Testing**: Use `./run_tests.sh` only (no `:lua` interactive testing for local functions)

**Tools:**
- Test runner: `./run_tests.sh` (normal, verbose, watch modes)
- TDD framework: plenary.nvim with mocking
- Mock system: HTTP request mocking for network-free testing
