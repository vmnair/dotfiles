-- readwise.lua
-- author: Vinod M. Nair MD
local M = {}

M.config = {
  -- API Configuration
  api_token = nil,
  base_url = "https://readwise.io/api/v2/",

  -- File Storage
  -- TODO: Need to implement settings to add file storge path
  cache_dir = "/Users/vinodnair/Library/CloudStorage/Dropbox/notebook/readwise/",

  -- Cache duration (in seconds)
  cache_duration = {
    highlights = 24 * 60 * 60, -- 24 hours
    books = 7 * 24 * 60 * 60, -- 7 days
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
  if not vim.fn.isdirectory(cache_dir) then
    vim.fn.mkdir(cache_dir, "p")
    if M.config.debug then
      print("Created cache_directory: " .. cache_dir)
    end
  end

  -- Validate API token
  if not M.config.api_token then
    vim.notify("Readwise API token is not set. Please set it in your configuration.", vim.log.levels.ERROR)
  end

  -- Debug output
  if M.config.debug then
    print("Readwise Setup Complete!")
    print(vim.inspect(M.config))
  end
end

-- API Functions
function M.get_highlights()
  --
  -- TODO: Add error handling and authentication
  local cmd = { "curl", "-s", M.config.base_url .. "export/" }
  local response = vim.fn.system(cmd)
  return vim.json.decode(response)
end

return M
