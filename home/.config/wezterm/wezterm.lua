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

-- Native WezTerm splits, independent of herdr/tmux (whatever's running inside
-- a pane, even plain zsh with nothing launched yet). Cmd-based so these never
-- collide with herdr's Ctrl+b prefix — WezTerm's own keytable intercepts
-- keys before the shell ever sees them, so Ctrl+b here would steal herdr's.
-- Same h/n/jkl; letters as herdr for muscle memory.
local act = wezterm.action
config.keys = {
	{ key = "h", mods = "CMD", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) }, -- side-by-side
	{ key = "n", mods = "CMD", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },  -- top/bottom
	{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Down") },
	{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Up") },
	{ key = ";", mods = "CMD", action = act.ActivatePaneDirection("Right") },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },
	-- Cmd+W above shadows WezTerm's default tab-close binding, so restore it explicitly.
	{ key = "w", mods = "CMD|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },

	-- Resize the active pane, same j/k/l/; directions as everything else.
	-- CMD+ALT so it doesn't collide with the plain CMD bindings above.
	{ key = "j", mods = "CMD|ALT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "k", mods = "CMD|ALT", action = act.AdjustPaneSize({ "Down", 3 }) },
	{ key = "l", mods = "CMD|ALT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = ";", mods = "CMD|ALT", action = act.AdjustPaneSize({ "Right", 3 }) },

	-- Swap the active pane with its neighbor by rotating pane order.
	{ key = "r", mods = "CMD|ALT", action = act.RotatePanes("Clockwise") },
}

return config
