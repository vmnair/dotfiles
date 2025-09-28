-- Tests for readwise.lua module
-- Run with: "nvim --headless -u tests/minimal_init.lua -c
-- "PlenaryBustedDirectory tests" -c "quit"

local readwise = require("lua.vinod.readwise")

describe("Readwise Configuration", function()
  before_each(function()
    -- Reset the global state before each test
    package.loaded["lua.vinod.readwise"] = nil -- clear from package.loaded table.
    readwise = require("lua.vinod.readwise")
  end)
  it("should have default configuration", function()
    assert.is_not_nil(readwise.config, "Config should exist")
    assert.equals("https://readwise.io/api/v2/", readwise.config.base_url)
    assert.equals(true, readwise.config.integration.zk_enabled)
  end)

  it("should merge user options with defaults", function()
    local user_opts = {
      debug = true,
      integration = {
        todo_enabled = false,
      },
    }

    -- Action: Call setup with options
    readwise.setup(user_opts)

    -- Assert: Check merged configuration
    assert.equals(true, readwise.config.debug, "Debug should be set to true")
    assert.equals(false, readwise.config.integration.todo_enabled, "Todo should be disabled")
    assert.equals(true, readwise.config.integration.zk_enabled, "ZK should remain default (true)")
  end)
end)

describe("Readwise API Functions", function()
  local original_system

  before_each(function()
    -- Reset module state
    package.loaded["lua.vinod.readwise"] = nil
    readwise = require("lua.vinod.readwise")

    -- Mock vim.fn.system to avoid real HTTP calls
    original_system = vim.fn.system
    vim.fn.system = function(cmd)
      if type(cmd) == "table" and cmd[1] == "curl" then
        return vim.json.encode({
          results = {
            {
              id = 1,
              text = "This is a test highlight",
              book_id = 123,
              author = "Test Author",
              title = "Test Book",
            },
          },
          next = nil,
        })
      end
      return "" -- Fallback in case of other commands than curl
    end
  end)

  after_each(function()
    -- Restore original system function
    vim.fn.system = original_system
  end)

  it("should fetch highlights from Readwise API", function()
    local highlights = readwise.get_highlights()

    assert.is_not_nil(highlights, "Should return highlights data")
    assert.is_table(highlights.results, "Should have results array")
    assert.equals(1, highlights.results[1].id, "Should have highlight ID")
    assert.equals("This is a test highlight", highlights.results[1].text, "Should have correct text")
  end)

  it("should handle API errors gracefully", function()
    -- Mock error response
    vim.fn.system = function(cmd)
      return "curl: (6) Could not resolve host"
    end

    -- Test graceful error handling
    local success, result = pcall(readwise.get_highlights)
    assert.is_false(success, "Should fail gracefully on network error")
  end)
end)

describe("Readwise Async API Functions", function()
  local original_job

  before_each(function()
    -- Reset module state
    package.loaded["lua.vinod.readwise"] = nil
    readwise = require("lua.vinod.readwise")

    -- Mock plenary.job for async tests
    local job = require("plenary.job")
    original_job = job.new

    -- Mock job.new to simulate successful response
    job.new = function(opts)
      return {
        start = function()
          -- Simulate successful job completion
          vim.defer_fn(function()
            local mock_response = vim.json.encode({
              results = {
                {
                  id = 1,
                  text = "This is a test highlight",
                  book_id = 123,
                  author = "Test Author",
                  title = "Test Book",
                },
              },
              next = nil,
            })

            -- Call the on_exit callback with success
            opts.on_exit({
              result = function()
                return mock_response
              end,
              stderr_result = function()
                return {}
              end,
            }, 0) -- 0 = success exit code
          end, 10) -- Small delay to simulate async
        end,
      }
    end
  end)

  after_each(function()
    -- Restore original job.new function
    if original_job then
      require("plenary.job").new = original_job
    end
  end)

  it("should handle successful async API call", function()
    local callback_data, callback_error
    local completed = false

    -- Call async function
    readwise.get_highlights_async(function(data, error)
      callback_data = data
      callback_error = error
      completed = true
    end)

    -- Wait for async operation to complete
    vim.wait(1000, function()
      return completed
    end)
    -- Assert callback was called with correct data
    assert.is_true(completed, "Callback should be called")
    assert.is_not_nil(callback_data, "Callback should receive data")
    assert.is_nil(callback_error, "No error should occur")
    assert.is_table(callback_data.results, "Should have results array")
  end)
end)
