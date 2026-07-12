local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
-- Tab bar always visible: it hosts the integrated traffic-light buttons.
-- (Hiding it with one tab makes the buttons float over terminal content.)
config.hide_tab_bar_if_only_one_tab = false
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"  -- traffic-light buttons, no fat title bar

return config
