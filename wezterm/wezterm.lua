-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.enable_tab_bar = false

config.font = wezterm.font("JetBrains Mono")
config.color_scheme = "Catppuccin Mocha"
config.color_scheme = 'Tokyo Night Storm'
config.font_size = 16


return config
