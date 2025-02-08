-- Pull in the wezterm API
local wezterm = require("wezterm")
-- local act = wezterm.action
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
	-- if name then
	--   name = "TABLE: " .. name
	-- end
	window:set_right_status(name or "")
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
config.font = wezterm.font("JetBrains Mono")
config.color_scheme = "Tokyo Night Storm"
config.font_size = 16

-- Leader key for Wezterm <C-a>
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }
return config
