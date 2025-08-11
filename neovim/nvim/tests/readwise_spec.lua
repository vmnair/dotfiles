-- Tests for readwise.lua module
-- Run with: "nvim --headless -u tests/minimal_init.lua -c
-- "PlenaryBustedDirectory tests" -c "quit"

local readwise = require("lua.vinod.readwise") -- why do i have to use lua. here?

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

    -- Assertj Check merger configuration
    assert.equals(true, readwise.config.debug, "Debug should be set to true")
    assert.equals(false, readwise.config.integration.todo_enabled, "Todoo should be displayed")
    assert.equals(true, readwise.config.integration.zk_enabled, "ZK should remain default (true)")
  end)
end)

describe("Readwise API Functions", function()
  local original_system

  before_each(function()
    --Reset module state
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
      return ""
    end
  end)

  after_each(function()
    -- Restore original system function
    vim.fn.sytem = original_system
  end)

  it("should fetch highlights from Readwise API", function()
    -- jthis function does not exist yet
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

    -- This function does not exist yet either
    local success, result = pcall(readwise.get_highlights)
    assert.is_false(success, "Should fail gracefully on network error")
  end)
end)
