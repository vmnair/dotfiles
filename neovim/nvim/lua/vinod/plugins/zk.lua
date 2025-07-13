return {
  "zk-org/zk-nvim",
  config = function()
    require("zk").setup({
      -- picker = "snacks_picker",
      picker = "fzf_lua",
      snacks_picker = {
        layout = {
          preset = "ivy",
        },
      },
    })

    local function show_zk_aliases()
      local function parse_zk_config()
        local config_path = vim.fn.expand("~/Library/CloudStorage/Dropbox/notebook/.zk/config.toml")
        local aliases = {}

        -- Try to read the config file
        local file = io.open(config_path, "r")
        if not file then
          -- Fallback: return basic aliases if config not found
          return {
            { key = "daily", desc = "Create daily journal entry", cmd = "ZkNew { group = 'journal' }" },
            {
              key = "new",
              desc = "Create new note with title",
              cmd = "ZkNew { title = vim.fn.input('Title: ') }",
            },
            {
              key = "ls",
              desc = "List recent notes",
              cmd = "ZkNotes { sort = { 'modified' } }",
            },
            { key = "tags",  desc = "Browse by tags",             cmd = "ZkTags" },
          }
        end

        local content = file:read("*all")
        file:close()

        -- Parse [alias] section
        local in_alias_section = false
        for line in content:gmatch("[^\r\n]+") do
          line = line:match("^%s*(.-)%s*$") -- trim whitespace

          if line == "[alias]" then
            in_alias_section = true
          elseif line:match("^%[") and line ~= "[alias]" then
            in_alias_section = false
          elseif in_alias_section and line:match("^([%w%-]+)%s*=") then
            local key, rest = line:match("^([%w%-]+)%s*=%s*(.+)")
            if key and rest then
              -- Extract description from command if possible
              local desc = "Execute " .. key .. " command"
              if key == "daily" then
                desc = "Create daily journal entry"
              elseif key == "oms" then
                desc = "Create OMS note"
              elseif key == "oms-staff" then
                desc = "Create OMS staff discussion"
              elseif key == "oms-admin" then
                desc = "Create OMS admin discussion"
              elseif key == "practice" then
                desc = "Create practice note"
              elseif key == "research" then
                desc = "Create research note"
              elseif key == "card" then
                desc = "Create cardiology note"
              elseif key == "hca" then
                desc = "Create administration note"
              elseif key == "zk" then
                desc = "Create zk development note"
              elseif key == "lua" then
                desc = "Create lua development note"
              elseif key == "c" then
                desc = "Create C development note"
              elseif key == "go" then
                desc = "Create Go development note"
              elseif key == "ls" then
                desc = "List recent notes"
              elseif key == "recent" then
                desc = "Show recent notes"
              elseif key == "search" then
                desc = "Search notes by tag"
              elseif key == "editlast" then
                desc = "Edit last modified note"
              elseif key == "edit" then
                desc = "Edit notes interactively"
              elseif key == "config" then
                desc = "Edit zk configuration"
              end

              table.insert(aliases, {
                key = key,
                desc = desc,
                cmd = "terminal zk " .. key,
              })
            end
          end
        end

        -- Add some built-in zk-nvim commands
        table.insert(aliases, {
          key = "new",
          desc = "Create new note with title",
          cmd = "ZkNew { title = vim.fn.input('Title: ') }",
        })
        table.insert(aliases, { key = "tags", desc = "Browse by tags", cmd = "ZkTags" })
        table.insert(aliases, {
          key = "fzf-search",
          desc = "Search notes",
          cmd = "ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }",
        })

        return aliases
      end

      local aliases = parse_zk_config()

      local items = {}
      local commands = {}
      for _, alias in ipairs(aliases) do
        local display_text = string.format("%-12s %s", alias.key, alias.desc)
        table.insert(items, display_text)
        commands[display_text] = alias.cmd
      end

      require("fzf-lua").fzf_exec(items, {
        prompt = "ZK Aliases> ",
        preview_window = "hidden",
        actions = {
          ["default"] = function(selected, opts)
            if selected and #selected > 0 then
              local cmd = commands[selected[1]]
              if cmd then
                vim.cmd(cmd)
              end
            end
          end,
        },
        winopts = {
          height = 0.6,
          width = 0.8,
          title = " ZK Aliases ",
          title_pos = "center",
        },
      })
    end

    -- Function to add selected text as hashtag to the last line of the file
    local function add_hashtag_from_text(selected_text)
      local buf = vim.api.nvim_get_current_buf()
      
      if selected_text == "" then
        print("No text selected")
        return
      end
      
      -- Convert to hashtag format
      local hashtag = selected_text:lower()
      hashtag = hashtag:gsub("^%s+", ""):gsub("%s+$", "")  -- trim leading and trailing whitespace first
      hashtag = hashtag:gsub("%s+", "-")  -- replace spaces with dashes
      hashtag = hashtag:gsub("[^%w%-]", "")  -- remove non-alphanumeric characters except dashes
      hashtag = hashtag:gsub("%-+", "-")  -- replace multiple dashes with single dash
      hashtag = hashtag:gsub("^%-+", ""):gsub("%-+$", "")  -- remove leading and trailing dashes
      hashtag = "#" .. hashtag
      
      -- Get the last line of the file
      local line_count = vim.api.nvim_buf_line_count(buf)
      local last_line = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1]
      
      -- Check if the hashtag already exists in the last line
      if last_line and last_line:find(hashtag, 1, true) then
        print("Hashtag '" .. hashtag .. "' already exists in the last line")
        return
      end
      
      -- Append the hashtag to the last line
      local new_last_line = (last_line or "") .. " " .. hashtag
      vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, {new_last_line})
      
      print("Added hashtag: " .. hashtag)
    end

    local opts = { noremap = true, silent = false }

    -- Create a new note after asking for its title.
    vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)
    -- Open notes.
    vim.api.nvim_set_keymap("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
    -- Open notes associated with the selected tags.
    vim.api.nvim_set_keymap("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

    -- Search for the notes matching a given query.
    vim.api.nvim_set_keymap(
      "n",
      "<leader>zf",
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      opts
    )
    -- Search for the notes matching the current visual selection.
    vim.api.nvim_set_keymap("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)

    -- Add hashtag from visual selection
    vim.api.nvim_set_keymap("v", "<leader>za", "", {
      noremap = true,
      silent = true,
      callback = function()
        -- Get selected text directly while in visual mode
        local save_reg = vim.fn.getreg('"')
        local save_regtype = vim.fn.getregtype('"')
        
        -- Yank the visual selection
        vim.cmd('normal! y')
        local selected_text = vim.fn.getreg('"')
        
        -- Restore the register
        vim.fn.setreg('"', save_reg, save_regtype)
        
        -- Process the selected text
        add_hashtag_from_text(selected_text)
      end,
      desc = "Add selected text as hashtag to last line",
    })

    -- Show ZK aliases
    vim.api.nvim_set_keymap("n", "<leader>zh", "", {
      noremap = true,
      silent = true,
      callback = show_zk_aliases,
      desc = "Show ZK aliases",
    })
  end,
}
