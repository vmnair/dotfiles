return {
  "zk-org/zk-nvim",
  ft = { "markdown", "zk", "zettelkasten" },
  config = function()
    require("zk").setup({
      picker = "snacks_picker",
      -- picker = "fzf_lua",
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
      hashtag = hashtag:gsub("^%s+", ""):gsub("%s+$", "") -- trim leading and trailing whitespace first
      hashtag = hashtag:gsub("%s+", "-")               -- replace spaces with dashes
      hashtag = hashtag:gsub("[^%w%-]", "")            -- remove non-alphanumeric characters except dashes
      hashtag = hashtag:gsub("%-+", "-")               -- replace multiple dashes with single dash
      hashtag = hashtag:gsub("^%-+", ""):gsub("%-+$", "") -- remove leading and trailing dashes
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
      vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count, false, { new_last_line })

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
        vim.cmd("normal! y")
        local selected_text = vim.fn.getreg('"')

        -- Restore the register
        vim.fn.setreg('"', save_reg, save_regtype)

        -- Process the selected text
        add_hashtag_from_text(selected_text)
      end,
      desc = "Add selected text as hashtag to last line",
    })

    -- Function to create todo from current line in zk note
    local function create_todo_from_zk_line()
      local line = vim.api.nvim_get_current_line()

      -- Clean up the line text for todo description
      local description = line:gsub("^%s*", ""):gsub("%s*$", "")

      if description == "" then
        print("Current line is empty")
        return
      end

      -- Import todo_manager to access dynamic categories and functions
      local todo_manager = require("vinod.todo_manager")

      -- Get dynamic categories from todo_manager
      local categories = {}
      for _, cat in ipairs(todo_manager.config.categories) do
        table.insert(categories, cat)
      end

      -- Step 1: Category selection
      vim.ui.select(categories, {
        prompt = "Select category for todo:",
      }, function(selected_category)
        if not selected_category then
          print("Todo creation cancelled")
          return
        end

        -- Step 2: Show date selection
        vim.ui.select({ "Pick show date", "Skip" }, {
          prompt = "Show date (when todo appears):",
        }, function(show_choice)
          local show_date = ""

          local function handle_due_date()
            -- Step 3: Due date selection
            vim.ui.select({ "Pick due date", "Skip" }, {
              prompt = "Due date:",
            }, function(due_choice)
              local due_date = ""

              local function create_final_todo()
                -- Create the todo
                local success =
                    todo_manager.add_todo(description, selected_category, {}, due_date, show_date)
                if success then
                  local show_display = show_date
                      and show_date ~= ""
                      and " [Show: " .. show_date .. "]"
                      or ""
                  local due_display = due_date and due_date ~= "" and " [Due: " .. due_date .. "]"
                      or ""
                  print(
                    "✓ Todo created: "
                    .. description
                    .. " ("
                    .. selected_category
                    .. ")"
                    .. show_display
                    .. due_display
                  )
                else
                  print("✗ Failed to create todo")
                end
              end

              if due_choice == "Pick due date" then
                todo_manager.get_date_input(function(picked_due)
                  if picked_due then
                    due_date = picked_due
                  end
                  create_final_todo()
                end)
              else
                create_final_todo()
              end
            end)
          end

          if show_choice == "Pick show date" then
            todo_manager.get_date_input(function(picked_show)
              if picked_show then
                show_date = picked_show
              end
              handle_due_date()
            end)
          else
            handle_due_date()
          end
        end)
      end)
    end

    -- Create todo from current line
    vim.api.nvim_set_keymap("n", "<leader>zT", "", {
      noremap = true,
      silent = true,
      callback = create_todo_from_zk_line,
      desc = "Create todo from current line",
    })

    -- Function to show comprehensive ZK help
    local function show_zk_help()
      local keymaps = {
        ["Core ZK Commands"] = {
          ["<leader>zn"] = "Create new note with title prompt",
          ["<leader>zo"] = "Open notes (sorted by modified date)",
          ["<leader>zt"] = "Browse notes by tags",
          ["<leader>zf"] = "Search notes by query (normal mode)",
          -- ["<leader>zf"] = "Search notes matching visual selection (visual mode)"
        },
        ["ZK Aliases & Shortcuts"] = {
          ["<leader>zh"] = "Show this comprehensive help window",
        },
        ["Text & Todo Integration"] = {
          ["<leader>za"] = "Add selected text as hashtag to last line (visual mode)",
          ["<leader>zT"] = "Create todo from current line (with category/date picker)",
        },
        ["Built-in ZK Commands (via :Zk...)"] = {
          [":ZkNew"] = "Create new note",
          [":ZkNotes"] = "List/search notes",
          [":ZkTags"] = "Browse by tags",
          [":ZkMatch"] = "Search in visual selection",
          [":ZkCd"] = "Change to zk notebook directory",
          [":ZkIndex"] = "Index the notebook",
        },
        ["Common ZK Aliases (from config.toml)"] = {
          ["daily"] = "zk daily - Create daily journal entry",
          ["oms"] = "zk oms - Create OMS note",
          ["practice"] = "zk practice - Create practice note",
          ["research"] = "zk research - Create research note",
          ["card"] = "zk card - Create cardiology note",
          ["ls"] = "zk ls - List recent notes",
          ["search"] = "zk search - Search by tags",
          ["editlast"] = "zk editlast - Edit last modified note",
          ["config"] = "zk config - Edit zk configuration",
        },
        ["Workflow Tips"] = {
          ["Quick note"] = "<leader>zn then type title",
          ["Browse recent"] = "<leader>zo to see recent notes",
          ["Find by tag"] = "<leader>zt to browse tags",
          ["Search content"] = "<leader>zf then type search term",
          ["Add hashtag"] = "Select text, then <leader>za",
          ["Line to todo"] = "Place cursor on line, then <leader>zT",
          ["Quick aliases"] = "<leader>zh for template shortcuts",
        },
      }

      -- Create floating window
      local width = 85
      local height = 30
      local buf = vim.api.nvim_create_buf(false, true)

      local lines = {}
      table.insert(lines, "📝 ZK (Zettelkasten) Help")
      table.insert(lines, string.rep("═", width - 4))
      table.insert(lines, "")

      for section, items in pairs(keymaps) do
        table.insert(lines, "▶ " .. section)
        table.insert(lines, string.rep("─", #section + 2))
        table.insert(lines, "")

        for key, desc in pairs(items) do
          local line = string.format("  %-25s %s", key, desc)
          if #line > width - 4 then
            -- Wrap long lines
            local key_part = string.format("  %-25s", key)
            table.insert(lines, key_part)
            table.insert(lines, string.format("  %25s %s", "", desc))
          else
            table.insert(lines, line)
          end
        end
        table.insert(lines, "")
      end

      table.insert(lines, string.rep("═", width - 4))
      table.insert(lines, "Notebook location: ~/Library/CloudStorage/Dropbox/notebook/")
      table.insert(lines, "Press 'q' or ESC to close")

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "filetype", "zkhelp")

      -- Center the window
      local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        anchor = "NW",
        style = "minimal",
        border = "rounded",
        title = " 📚 ZK Help ",
        title_pos = "center",
      }

      local win = vim.api.nvim_open_win(buf, true, win_opts)

      -- Set up syntax highlighting
      vim.cmd("syntax match ZkHelpTitle /^📝.*$/")
      vim.cmd("syntax match ZkHelpSection /^▶.*$/")
      vim.cmd("syntax match ZkHelpSeparator /^[═─].*$/")
      vim.cmd("syntax match ZkHelpKey /^  [^[:space:]].*$/")
      vim.cmd("syntax match ZkHelpFooter /^Press.*$/")
      vim.cmd("syntax match ZkHelpLocation /^Notebook.*$/")

      vim.cmd("highlight ZkHelpTitle ctermfg=14 guifg=#00D7D7 cterm=bold gui=bold")
      vim.cmd("highlight ZkHelpSection ctermfg=11 guifg=#FFD700 cterm=bold gui=bold")
      vim.cmd("highlight ZkHelpSeparator ctermfg=8 guifg=#666666")
      vim.cmd("highlight ZkHelpKey ctermfg=10 guifg=#90EE90")
      vim.cmd("highlight ZkHelpFooter ctermfg=8 guifg=#888888")
      vim.cmd("highlight ZkHelpLocation ctermfg=12 guifg=#87CEEB")

      -- Close window on 'q' or ESC
      vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "<cmd>close<CR>", { noremap = true, silent = true })
    end

    -- Show comprehensive ZK help
    vim.api.nvim_set_keymap("n", "<leader>zh", "", {
      noremap = true,
      silent = true,
      callback = show_zk_help,
      desc = "Show ZK help",
    })
  end,
}
