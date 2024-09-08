-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
-- This will hold the configuration.
-- local config = wezterm.config_builder()
local config = {}

-- use config_builder if it is available
if wezterm.config_builder then
	config = wezterm.config_builder()
end
-- Local functions
-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window, _)
	local name = window:active_key_table()
	if name then
		name = "TABLE: " .. name
	end
	window:set_right_status(name or "")
end)

config.window_background_opacity = 0.9
config.window_decorations = "RESIZE"
config.default_workspace = "home"

-- Show tabbar
config.enable_tab_bar = false
config.tab_bar_at_bottom = false -- default is top
config.use_fancy_tab_bar = false
-- config.tab_max_width = 32
-- config.switch_to_last_active_tab_when_closing_tab = true
-- config.pane_focus_follows_mouse = true
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
config.font = wezterm.font("JetBrains Mono")
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Tokyo Night Storm"
config.font_size = 16

-- -- Leader key for Wezterm <C-a>
-- config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
--
-- -- Key configuration
-- config.keys = {
--   -- Toogle zoom pane
--   {
--     key = "z",
--     mods = "LEADER",
--     action = act.TogglePaneZoomState,
--   },
--   -- Split into panes
--   {
--     key = "|",
--     mods = "LEADER",
--     action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
--   },
--   {
--     key = "_",
--     mods = "LEADER",
--     action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
--   },
--
--   -- Switch panes
--   {
--     key = "{",
--     mods = "LEADER",
--     action = act.PaneSelect({ mode = "SwapWithActiveKeepFocus" }),
--   },
--
--   -- Adjust Pane Size
--   {
--     key = "RightArrow",
--     mods = "LEADER",
--     action = act.AdjustPaneSize({ "Right", 5 }),
--   },
--   {
--     key = "LeftArrow",
--     mods = "LEADER",
--     action = act.AdjustPaneSize({ "Left", 5 }),
--   },
--   {
--     key = "UpArrow",
--     mods = "LEADER",
--     action = act.AdjustPaneSize({ "Up", 5 }),
--   },
--   {
--     key = "DownArrow",
--     mods = "LEADER",
--     action = act.AdjustPaneSize({ "Down", 5 }),
--   },
--
--   -- Move betweeen panes
--   {
--     key = "h",
--     mods = "LEADER",
--     action = act.ActivatePaneDirection("Left"),
--   },
--   {
--     key = "l",
--     mods = "LEADER",
--     action = act.ActivatePaneDirection("Right"),
--   },
--   {
--     key = "k",
--     mods = "LEADER",
--     action = act.ActivatePaneDirection("Up"),
--   },
--   {
--     key = "j",
--     mods = "LEADER",
--     action = act.ActivatePaneDirection("Down"),
--   },
--
--   -- Activate resize table
--   {
--     key = "r",
--     mods = "LEADER",
--     action = act.ActivateKeyTable({
--       name = "resize_pane",
--       one_shot = false,
--     }),
--   },
--
--   --Copy mode
--   {
--     key = "[",
--     mods = "LEADER",
--     action = wezterm.action.ActivateCopyMode,
--   },
--   -- Create a new tab
--   {
--     key = "t",
--     mods = "LEADER",
--     action = act.SpawnTab("CurrentPaneDomain"),
--   },
--
--   {
--     key = "n",
--     mods = "LEADER",
--     action = wezterm.action.ActivateTabRelative(1),
--   },
--
--   {
--     key = "p",
--     mods = "LEADER",
--     action = wezterm.action.ActivateTabRelative(-1),
--   },
--   -- Tab Management
--   -- name a tab
--   {
--     key = "e", -- Edit tab
--     mods = "LEADER",
--     action = act.PromptInputLine({
--       description = "Tab Name: ",
--       action = wezterm.action_callback(function(window, _, line)
--         if line then
--           window:active_tab():set_title(line)
--         end
--       end),
--     }),
--   },
--
--   -- Navigate tabs
--   {
--     key = "w",
--     mods = "LEADER",
--     action = act.ShowTabNavigator,
--   },
--
--   -- Close tab
--   {
--     key = "x",
--     mods = "LEADER",
--     action = act.CloseCurrentTab({ confirm = true }),
--   },
--
--   -- Mux server connection
--   {
--     key = "a",
--     mods = "LEADER",
--     action = act.AttachDomain("unix"),
--   },
--
--   {
--     key = "d",
--     mods = "LEADER",
--     action = act.DetachDomain({ DomainName = "unix" }),
--   },
--   -- rename current session
--   {
--     key = "$",
--     mods = "LEADER|SHIFT",
--     action = act.PromptInputLine({
--       description = "Enter new name for session",
--       action = wezterm.action_callback(function(window, pane, line)
--         if line then
--           mux.rename_workspace(window:mux_window():get_workspace(), line)
--         end
--       end),
--     }),
--   },
--   -- Show list of workspaces
--   {
--     key = "s",
--     mods = "LEADER",
--     action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
--   },
-- }
--
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
--
-- -- Mux server configuration
-- config.unix_domains = {
--   {
--     name = "unix",
--   },
-- }

return config
