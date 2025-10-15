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

describe("Readwise Async API Functions", function()
	local original_job
	local original_getenv

	before_each(function()
		-- Reset module state
		package.loaded["lua.vinod.readwise"] = nil
		readwise = require("lua.vinod.readwise")

		-- Mock os.getenv to provide test token
		original_getenv = os.getenv
		os.getenv = function(var)
			if var == "READWISE_TOKEN" then
				return "test_token_123"
			end
			return original_getenv(var)
		end

		-- Mock plenary.job for async tests
		local job = require("plenary.job")
		original_job = job.new

		-- Mock job.new to simulate successful response
		job.new = function(self, opts)
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
								return { mock_response } -- Return as array of lines
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
		-- Restore original functions
		if original_job then
			require("plenary.job").new = original_job
		end
		if original_getenv then
			os.getenv = original_getenv
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

-- Testing Cache Functions
describe("Readwise Cache Functions", function()
	local test_cache_dir

	before_each(function()
		-- reset module
		package.loaded["lua.vinod.readwise"] = nil
		readwise = require("lua.vinod.readwise")

		-- Use a temporary cache directory for testing
		test_cache_dir = "/tmp/readwise_test_cache/"
		-- Ensure directory exists
		vim.fn.mkdir(test_cache_dir, "p")
		readwise.setup({ cache_dir = test_cache_dir })
	end)

	after_each(function()
		-- Clean up test files
		vim.fn.delete(test_cache_dir, "rf")
	end)

	it("should cache data to file", function()
		local test_data = {
			count = 2,
			results = { { id = 1, text = "test" } },
		}

		local success, err = readwise.test_cache_data(test_data, "highlights")
		assert.is_true(success, "Cache should succeed")
		assert.is_nil(err, "No error should occur")

		-- Verify file exists
		local cache_file = test_cache_dir .. "highlights_cache.json"
		local file = io.open(cache_file, "r")
		local content = file:read("*a")
		file:close()

		local cached = vim.json.decode(content)
		assert.is_not_nil(cached.timestamp, "Should have timestamp")
		assert.equals("highlights", cached.cache_type)
		assert.equals(2, cached.data.count)
	end)

	it("should load cached data", function()
		local test_data = {
			count = 2,
			results = { { id = 1, text = "test" } },
		}

		local success, err = readwise.test_cache_data(test_data, "highlights")
		assert.is_true(success, "Should cache successfully")

		-- Load it back
		local cached, data_err = readwise.test_load_cached_data("highlights")
		assert.is_not_nil(cached, "Cache should not be nil")
		assert.is_nil(data_err, "There should not be an error")

		-- Verify structure
		assert.is_not_nil(cached.timestamp, "Should have timestamp")
		assert.equals("highlights", cached.cache_type, "Should have cache_type")
		assert.is_table(cached.data, "Data should be a table")

		-- Verify data matches what was cached
		assert.equals(2, cached.data.count, "Count should match")
		assert.equals("test", cached.data.results[1].text, "text should match")
	end)

	describe("Readwise Cache Invalidation", function()
		it("should validate fresh cache as valid", function()
			-- Create frech cache
			local test_data = { text = "Fresh highlight" }
			readwise.test_cache_data(test_data, "highlights")

			-- Check validation
			local is_valid = readwise.test_is_cache_valid("highlights")
			assert.is_true(is_valid, "Fresh cache should be valid")
		end)

		it("should return false for non-existant cache", function()
			-- Try to validate non-existant cache
			local is_valid = readwise.test_is_cache_valid("nonexistant_type")
			assert.is_false(is_valid, "Non-existant cache should be invalid")
		end)

		it("should return false for stale cache", function()
			-- Create cache with old timestamp ( 10 hours ago)
			-- Default is 4 hours, so this would be stale.
			local test_data = { text = "Old highlight" }
			local cache_path = test_cache_dir .. "/hightlights.json"
			local stale_cache = {
				timestamp = os.time() - (10 * 60 * 60), -- 10 hours ago
				cache_type = "highlights",
				data = test_data,
			}

			local file = io.open(cache_path, "w")
			file:write(vim.json.encode(stale_cache))
			file:close()

			-- Should be invalid (older than 4 hour limit)
			local is_valid = readwise.test_is_cache_valid("highlights")
			assert.is_false(is_valid, "Stale cache should be invalid")
		end)

		it("should return false for cache without timestamp", function()
			-- Create corrupt cache (no timestamp)
			local cache_path = test_cache_dir .. "/hightlights.json"
			local corrupt_cache = {
				cache_type = "highlights",
				data = { text = "No timestamp" },
				-- Missing timestamp field!
			}

			local file = io.open(cache_path, "w")
			file:write(vim.json.encode(corrupt_cache))
			file:close()

			-- Should be invalid (corrupt cache structure)
			local is_valid = readwise.test_is_cache_valid("highlights")
			assert.is_false(is_valid, "Cache without timestamp should ve invalid")
		end)
	end)
end)

describe("Readwise Smart Cache Orchestration", function()
	it("should return cached data when cache is fresh", function()
		-- Set up test cache directory
		local test_cache_dir = "/tmp/readwise_test_cache"
		vim.fn.mkdir(test_cache_dir, "p")
		readwise.setup({ cache_dir = test_cache_dir })
		local test_data = {
			text = "Cached highlights",
		}
		-- Add test data to cache
		readwise.test_cache_data(test_data, "highlights")

		-- Call get_highlights
		local callback_data, callback_error
		local completed = false

		readwise.get_highlights(function(data, error)
			callback_data = data
			callback_error = error
			completed = true
		end, false)
		-- Wait for async operation to complete
		vim.wait(1000, function()
			return completed
		end)

		-- Assert callback was called with Cached data
		assert.is_true(completed, "Callback should be called")
		assert.is_not_nil(callback_data, "Callbac should recieve data")
		assert.is_nil(callback_error, "No error should occur")
		assert.equals("Cached highlights", callback_data.data.text, "Should return cached data")

		-- Clean up
		vim.fn.delete(test_cache_dir, "rf")
	end)

	it("should fetch new data when cache is stale or missing", function()
		-- Set up test cache directory
		local test_cache_dir = "/tmp/readwise_test_cache/"
		vim.fn.mkdir(test_cache_dir, "p")
		readwise.setup({ cache_dir = test_cache_dir })
		local cache_file = test_cache_dir .. "highlights_cache.json"

		-- Create STALE  cache
		local now = os.time()
		-- 5 hours ago
		local five_hours_ago = now - (5 * 60 * 60)

		-- Create cache with old timestamp
		local stale_cache_content = {
			timestamp = five_hours_ago,
			cache_type = "highlights",
			data = { text = "Stale cached highlights" },
		}

		local file = io.open(cache_file, "w")
		file:write(vim.json.encode(stale_cache_content))
		file:close()

		-- Mock the API call (Since the cache is stale, API should be called)
		local original_get_highlights_async = readwise.get_highlights_async
		local api_was_called = false

		readwise.get_highlights_async = function(callback)
			api_was_called = true
			-- Simulat API response
			callback({ text = "Fresh API highlights" }, nil)
		end

		-- Call get_highlights
		local callback_data, callback_error
		local completed = false

		readwise.get_highlights(function(data, err)
			callback_data = data
			callback_error = err
			completed = true
		end, false) -- false = don't force refresh

		-- Wait for async operation to complete
		vim.wait(1000, function()
			return completed
		end)

		-- Assertions
		assert.is_true(completed, "Callback should be called")
		assert.is_true(api_was_called, "API should be called for stale cache")
		assert.is_not_nil(callback_data, "Should receive data")
		assert.is_nil(callback_error, "No error should occur")
		assert.equals("Fresh API highlights", callback_data.text, "Should return fresh API data, not stale cache")

		-- Restore original function
		readwise.get_highlights_async = original_get_highlights_sync

		-- Clean up
		vim.fn.delete(test_cache_dir, "rf")
	end)
end)
