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
    highlights = 4 * 60 * 60,  -- 4 hours (fresh data, still efficient)
    books = 24 * 60 * 60,      -- 24 hours (books change less frequently)
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
    auto_tag = true,   -- Auto-tag hightlights by book/author
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
  if cache_dir and cache_dir ~= "" then     -- validate cache_dir
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
      "-s",                          -- silent mode
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

return M
