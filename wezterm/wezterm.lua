-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local config = {}
-- maximize on startup
wezterm.on("gui-startup", function(cmd)
  local mux = wezterm.mux
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Local functions
-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window, _)
  local name = window:active_key_table()
  if name then
    name = "TABLE: " .. name
  end
  window:set_right_status(name or "")

  config.window_background_opacity = 0.8
end)

config.window_background_opacity = 0.9
config.default_workspace = "home"
config.enable_tab_bar = false
config.tab_bar_at_bottom = true -- default is top
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.switch_to_last_active_tab_when_closing_tab = true
config.pane_focus_follows_mouse = true
config.scrollback_lines = 5000

--  No padding between panes
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.colors = {
  tab_bar = {
    background = "#1a1b26",
    active_tab = {
      bg_color = "#1a1b26",
      fg_color = "#7aa2f7",
    },
  },
}

-- Font configuration
--config.font = wezterm.font("JetBrains Mono")
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 18
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Tokyo Night Storm"

-- Leader key for Wezterm <C-a>
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Key configuration
config.keys = {
  -- Toogle zoom pane
  {
    key = "z",
    mods = "LEADER",
    action = act.TogglePaneZoomState,
  },
  -- Split into panes
  {
    key = "\\",
    mods = "LEADER",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "-",
    mods = "LEADER",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  -- Switch panes
  {
    key = "{",
    mods = "LEADER",
    action = act.PaneSelect({ mode = "SwapWithActiveKeepFocus" }),
  },
  -- Adjust Pane Size
  {
    key = "RightArrow",
    mods = "LEADER",
    action = act.AdjustPaneSize({ "Right", 5 }),
  },
  {
    key = "LeftArrow",
    mods = "LEADER",
    action = act.AdjustPaneSize({ "Left", 5 }),
  },
  {
    key = "UpArrow",
    mods = "LEADER",
    action = act.AdjustPaneSize({ "Up", 5 }),
  },
  {
    key = "DownArrow",
    mods = "LEADER",
    action = act.AdjustPaneSize({ "Down", 5 }),
  },
  -- Move betweeen panes
  {
    key = "h",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Left"),
  },
  {
    key = "l",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Right"),
  },
  {
    key = "k",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Up"),
  },
  {
    key = "j",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Down"),
  },
  -- Activate resize table
  {
    key = "r",
    mods = "LEADER",
    action = act.ActivateKeyTable({
      name = "resize_pane",
      one_shot = false,
    }),
  },
  --Copy mode
  {
    key = "[",
    mods = "LEADER",
    action = wezterm.action.ActivateCopyMode,
  },
  -- Create a new tab
  {
    key = "t",
    mods = "LEADER",
    action = act.SpawnTab("CurrentPaneDomain"),
  },

  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action.ActivateTabRelative(1),
  },

  {
    key = "p",
    mods = "LEADER",
    action = wezterm.action.ActivateTabRelative(-1),
  },
  -- Tab Management
  -- name a tab
  {
    key = "e", -- Edit tab
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Tab Name: ",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  -- Navigate tabs
  {
    key = "w",
    mods = "LEADER",
    action = act.ShowTabNavigator,
  },
  -- Close tab
  {
    key = "x",
    mods = "LEADER",
    action = act.CloseCurrentTab({ confirm = true }),
  },
  -- Mux server connection
  {
    key = "a",
    mods = "LEADER",
    action = act.AttachDomain("unix"),
  },

  {
    key = "d",
    mods = "LEADER",
    action = act.DetachDomain({ DomainName = "unix" }),
  },
  -- Toggle pane zoom state
  {
    key = "f",
    mods = "LEADER",
    -- mods = "ALT",
    action = wezterm.action.TogglePaneZoomState,
  },
}

-- config.key_tables = {
--   resize_pane = {
--     { key = "LeftArrow",  action = act.AdjustPaneSize({ "Left", 1 }) },
--     { key = "h",          action = act.AdjustPaneSize({ "Left", 1 }) },
--
--     { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
--     { key = "l",          action = act.AdjustPaneSize({ "Right", 1 }) },
--
--     { key = "UpArrow",    action = act.AdjustPaneSize({ "Up", 1 }) },
--     { key = "k",          action = act.AdjustPaneSize({ "Up", 1 }) },
--
--     { key = "DownArrow",  action = act.AdjustPaneSize({ "Down", 1 }) },
--     { key = "j",          action = act.AdjustPaneSize({ "Down", 1 }) },
--
--     -- cancel this mode by pressing escape.
--     { key = "Escape",     action = "PopKeyTable" },
--   },
-- }

-- We can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
-- for i = 1, 9 do
--   table.insert(config.keys, {
--     key = tostring(i),
--     mods = "LEADER",
--     action = wezterm.action.ActivateTab(i - 1),
--   })
-- end
-- timeout_milliseconds defaults to 1000 and can be omitted
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  -- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
  {
    key = "a",
    mods = "LEADER|CTRL",
    action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
  },
  {
    key = "%",
    mods = "LEADER|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },

  {
    key = '"',
    mods = "LEADER|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
}

return config
