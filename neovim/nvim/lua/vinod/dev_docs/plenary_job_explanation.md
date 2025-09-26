# Plenary.job Asynchronous HTTP Requests - Detailed Explanation

Date: 2025-09-25
Context: Readwise Neovim Integration Development - Day 2 API Client Implementation

## Overview

This document explains how to use plenary.job for asynchronous HTTP requests in Neovim plugins, specifically for the Readwise API integration.

## Complete Function Implementation

```lua
local Job = require('plenary.job')

function M.get_highlights_async(callback)
  Job:new({
    command = 'curl',
    args = {
      '-s',
      '-H', 'Authorization: Token ' .. M.config.api_token,
      M.config.base_url .. 'export/'
    },
    on_exit = function(job, return_val)
      if return_val == 0 then
        local response = table.concat(job:result(), '\n')
        local success, data = pcall(vim.json.decode, response)
        if success then
          callback(data, nil)
        else
          callback(nil, 'JSON parsing error: ' .. data)
        end
      else
        local error_msg = table.concat(job:stderr_result(), '\n')
        callback(nil, 'Curl error: ' .. error_msg)
      end
    end,
  }):start()
end
```

## Line-by-Line Breakdown

### Import and Setup
```lua
local Job = require('plenary.job')
```
- **Imports** the Job class from plenary.nvim plugin
- **Job** is a constructor function that creates process objects
- **Must have** plenary.nvim installed as a dependency

### Function Declaration
```lua
function M.get_highlights_async(callback)
```
- **`callback`**: A function that will be called when the request completes
- **Callback pattern**: `callback(data, error)` where one will be nil
- **Asynchronous**: Function returns immediately, callback executes later

### Create New Job
```lua
Job:new({
```
- **`Job:new()`**: Constructor that creates a new process job
- **Takes table**: Configuration options for the process
- **Returns**: Job object with methods like `:start()`, `:result()`, etc.

### Specify Command
```lua
command = 'curl',
```
- **`command`**: The executable to run (must be in PATH)
- **String value**: Just the command name, not full path
- **plenary finds**: The executable using system PATH

### Command Arguments
```lua
args = {
  '-s',
  '-H', 'Authorization: Token ' .. M.config.api_token,
  M.config.base_url .. 'export/'
},
```
- **`args`**: Table of command-line arguments passed to curl
- **`'-s'`**: Silent flag (suppress progress meter)
- **`'-H'`**: Header flag, followed by the header value
- **String concatenation**: Builds authorization header with token
- **Final URL**: Constructs the full API endpoint URL

**Equivalent shell command:**
```bash
curl -s -H "Authorization: Token YOUR_TOKEN" https://readwise.io/api/v2/export/
```

### Exit Callback
```lua
on_exit = function(job, return_val)
```
- **`on_exit`**: Callback function executed when process finishes
- **`job`**: Reference to the Job object (access to results)
- **`return_val`**: Exit code from the process (0 = success, non-zero = error)
- **Asynchronous**: This function runs in the background when curl finishes

### Check Success
```lua
if return_val == 0 then
```
- **Exit code 0**: Unix convention for successful process completion
- **Success path**: Process curl's output and parse JSON
- **Failure path**: Handle errors (network, authentication, etc.)

### Get Process Output
```lua
local response = table.concat(job:result(), '\n')
```
- **`job:result()`**: Returns table of output lines from stdout
- **Example**: `{"line1", "line2", "line3"}`
- **`table.concat(..., '\n')`**: Joins lines back into single string
- **Result**: Complete JSON response as one string

### Parse JSON Safely
```lua
local success, data = pcall(vim.json.decode, response)
```
- **`pcall()`**: Protected call - catches errors without crashing
- **Returns**: `success` (boolean), `data` (result or error message)
- **`vim.json.decode()`**: Converts JSON string to Lua table
- **Safe parsing**: Won't crash if JSON is malformed

### Handle Success/Parse Errors
```lua
if success then
  callback(data, nil)
else
  callback(nil, 'JSON parsing error: ' .. data)
end
```
- **If JSON parsing succeeded**: Call callback with `(data, nil)`
- **If JSON parsing failed**: Call callback with `(nil, error_message)`
- **Callback convention**: `(result, error)` - one is always nil
- **`data` becomes error**: In pcall failure, second return value is error message

### Handle Process Errors
```lua
else
  local error_msg = table.concat(job:stderr_result(), '\n')
  callback(nil, 'Curl error: ' .. error_msg)
end
```
- **`job:stderr_result()`**: Gets error output from process (stderr)
- **Network errors**: "Could not resolve host", "Connection refused", etc.
- **API errors**: HTTP error responses from Readwise API
- **Join error lines**: Multiple error lines combined into single message

### Start the Job
```lua
}):start()
```
- **`:start()`**: Begins process execution immediately
- **Non-blocking**: Function returns immediately after starting
- **Background execution**: Process runs while Neovim continues normally
- **Callback later**: `on_exit` will be called when process completes

## Execution Flow

```
1. Call M.get_highlights_async(my_callback)
2. Job:new() creates process configuration
3. :start() launches curl in background
4. Function returns immediately (non-blocking)
5. User can continue using Neovim
6. curl finishes and triggers on_exit callback
7. on_exit processes results and calls my_callback
8. my_callback receives either (data, nil) or (nil, error)
```

## Usage Example

```lua
-- This doesn't block Neovim
M.get_highlights_async(function(highlights, error)
  if error then
    vim.notify('Failed: ' .. error, vim.log.levels.ERROR)
  else
    print('Got ' .. highlights.count .. ' highlights!')
    -- Process highlights data here
  end
end)

-- This code runs immediately, doesn't wait for API
print('API request started...')
```

## Key Insights

### Why Asynchronous is Important
- **UI Responsiveness**: Neovim remains usable during network requests
- **Better UX**: No freezing during potentially slow API calls
- **Error Isolation**: Network failures don't crash the editor

### plenary.job Advantages
- **Clean API**: Simpler than raw vim.loop
- **Error Handling**: Built-in stderr capture
- **Popular**: Standard in Neovim plugin ecosystem
- **Flexible**: Works for any command-line tool

### Callback Pattern
- **Convention**: `callback(result, error)` - exactly one is nil
- **Error-first**: Check for error before processing result
- **Composable**: Easy to chain or combine multiple async operations

## Integration with Readwise Project

This async pattern fits perfectly with:
- **TDD Development**: Can mock the callback for testing
- **UI Components**: Non-blocking data fetching for pickers
- **Caching Strategy**: Background refresh without interrupting workflow
- **Error Handling**: Graceful degradation when API is unavailable

## Next Steps for Day 2

1. **Implement this async function** in readwise.lua
2. **Add authentication** with proper token handling
3. **Create tests** that mock the Job behavior
4. **Add caching layer** that works with async pattern
5. **Build UI components** that use async data fetching