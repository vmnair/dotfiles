-- readwise.lua
-- author: Vinod M. Nair MD
local M = {}
-- import for plenary job
local Job = require("plenary.job")

M.config = {
	-- API Configuration
	api_token = nil,
	base_url = "https://readwise.io/api/v2/",

	-- File Storage
	-- Default to standard Neovim data directory (portable across systems)
	-- Users can override this to use Dropbox, iCloud, or any custom path:
	-- setup({ cache_dir = "~/Dropbox/notebook/readwise/" })
	cache_dir = vim.fn.stdpath("data") .. "/readwise/",

	-- Cache duration (in seconds)
	-- Safe to be aggressive - API limit is 240 req/min, not daily
	-- Users can override: setup({ cache_duration = { highlights = 60*60 } })
	cache_duration = {
		highlights = 4 * 60 * 60, -- 4 hours (fresh data, still efficient)
		books = 24 * 60 * 60, -- 24 hours (books change less frequently)
	},

	-- UI Configuration (FZF-lua integration)
	ui = {
		preview_width = 80,
		preview_height = 20,
		fzf_opts = {
			prompt = "Readwise> ",
			height = 0.8,
			width = 0.9,
		},
	},

	-- Integration with existing tools
	integration = {
		zk_enabled = true, -- Create zk notes from highlights
		todo_enabled = true, -- Create todo from highlights
		auto_tag = true, -- Auto-tag hightlights by book/author
	},

	-- Debug mode
	debug = false,
}

-- Setup function.
function M.setup(opts)
	-- Merge user options with default configuration
	-- This allows users to override default settings.
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	-- Create cache directory if it doesn't exist.
	local cache_dir = M.config.cache_dir
	if cache_dir and cache_dir ~= "" then -- validate cache_dir
		if not vim.fn.isdirectory(cache_dir) then -- check if directory exists.
			vim.fn.mkdir(cache_dir, "p")
		end
	else
		vim.notify("Cache directory is not configured ...", vim.log.levels.ERROR)
	end

	-- Validate API token
	if not M.config.api_token then
		vim.notify("Readwise API token is not set. Please set it in your configuration.", vim.log.levels.ERROR)
	end

	-- Debug output
	if M.config.debug then
		vim.notify("Readwise Setup Complete!", vim.log.levels.INFO)
	end
end

-- Function to get API token from environment variable or config
local function get_api_token()
	-- Try environment variable first
	local token = os.getenv("READWISE_TOKEN")

	-- Fallback to config value
	if not token or token == "" then
		token = M.config.api_token
	end

	-- validate we have a token
	if not token or token == "" then
		return nil, "Readwise API token not found.  Set READWISE_TOKEN env variable or configure in setup."
	end

	return token, nil
end

-- Save data to cache file with timestamp
-- @param data table: The data to cache (from API response)
-- @param cache_type string: Type of cache ("highlights" or "books")
-- @returns boolean, string: success, error_message (nil on success)
local function cache_data(data, cache_type)
	local cache_dir = M.config.cache_dir
	local filename = cache_type .. "_cache.json"
	local filepath = cache_dir .. filename

	-- Create cache structure with timestamp
	local cache = {
		timestamp = os.time(),
		data = data,
		cache_type = cache_type,
	}

	-- Open file for writing
	local file, err = io.open(filepath, "w")
	if not file then
		return false, "Failed to open cache file: " .. err
	end

	-- Encode data to json
	local json_str = vim.json.encode(cache)

	-- Write to file
	file:write(json_str)
	file:close()

	return true, nil
end

-- Load cached data if valid
-- @param cache_type string: ("highlights" or "books")
-- @returns table|nil, string|nil : data, error_message (nil on success)
--
local function load_cached_data(cache_type)
	-- Build file path
	local cache_dir = M.config.cache_dir
	local filename = cache_type .. "_cache.json"
	local filepath = cache_dir .. filename
	-- Check if file exists
	if vim.fn.filereadable(filepath) ~= 1 then
		return nil, "Cache file does not exist"
	end

	-- Open file for reading.
	local file, err = io.open(filepath, "r")
	if not file then
		return nil, "Failed to open the file: " .. err
	end

	-- Read file content
	local content = file:read("*a") -- read all
	file:close()

	-- Parse JSON (json.decode)
	local success, cached = pcall(vim.json.decode, content)
	if not success then
		return nil, "Failed to parse cache JSON: " .. cached
	end

	-- Return the cached data
	return cached, nil -- Success
end

-- Check if cached data is still valid (not expired)
-- param cache_type string: Type ("highlights" or "books")
-- returns boolean: true if cache is vaid and fresh, false otherwise
local function is_cache_valid(cache_type)
	-- load cached data
	local cached, err = load_cached_data(cache_type)
	if err then
		return false -- no cache or error loading
	end
	-- Check timestamp
	if not cached.timestamp then
		return false -- Corrupt cache
	end

	-- Calculate cache age in seconds
	local current_time = os.time()
	local cache_age = current_time - cached.timestamp

	-- Get max age from  config
	local max_age = M.config.cache_duration[cache_type]
	if not max_age then
		return false -- unknown cache type
	end
	-- Return freshness
	return cache_age < max_age
end

-- Async function to get highlights from Readwise API using Plenary.job
function M.get_highlights_async(callback)
	-- Get and valicate API token
	local token, token_err = get_api_token()
	if token_err then
		callback(nil, token_err)
		return
	end

	-- Set up Job configuration
	Job:new({
		command = "curl",
		args = {
			"-s", -- silent mode
			"-H",
			"Authorization: Token " .. token, -- auth header
			"-H",
			"Content-Type: application/json", -- content type
			M.config.base_url .. "export/", -- API endpoint
		},
		-- Handle job completion
		-- `on_exit` is a hook supplied to the `job.new` constructor.
		-- When the external process (`curl`) finishes, Neovim calls
		-- this function with **two** arguments:
		-- @params:
		-- `job_instance`: The `Job` object that was created by
		--  `job.new`. It exposes methods such as `:result()` and `
		-- :stderr_result()` to retrieve the stdout and stderr buffers.
		-- `exit_code`:  The numeric exit status returned by the child process. A value of `0` indicates success, any other value signals an error.
		on_exit = function(job_instance, exit_code)
			if exit_code == 0 then
				-- parse JSON response
				local output = table.concat(job_instance:result(), "\n")
				local success, parsed_data = pcall(vim.json.decode, output)

				if success then
					callback(parsed_data, nil)
				else
					callback(nil, "Failed to parse JSON response")
				end
			else
				-- Handle HTTP errors
				local error_output = table.concat(job_instance:stderr_result(), "\n")
				callback(nil, "API request failed: " .. error_output)
			end
		end,
	}):start() -- Start the async job
end

-- Temporary functions (remove before production)
function M.test_cache_data(data, cache_type)
	return cache_data(data, cache_type)
end

function M.test_load_cached_data(cache_type)
	return load_cached_data(cache_type)
end

-- Test helper for cache validation
function M.test_is_cache_valid(cache_type)
	return is_cache_valid(cache_type)
end

return M
