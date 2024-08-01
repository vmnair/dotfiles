-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
-- This will hold the configuration.
local config = wezterm.config_builder()

-- Leader key for Wezter
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
  -- Toogle zoom pane
  { key = "z",          mods = "LEADER", action = act.TogglePaneZoomState },
  -- Split into panes
  { key = "|",          mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-",          mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Adjust Pane Size
  { key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "LeftArrow",  mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "UpArrow",    mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "DownArrow",  mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
  -- Move betweeen panes
  { key = "h",          mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l",          mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k",          mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j",          mods = "LEADER", action = act.ActivatePaneDirection("Down") },
}

config.enable_tab_bar = false

config.font = wezterm.font("JetBrains Mono")
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Tokyo Night Storm"
config.font_size = 16

return config
