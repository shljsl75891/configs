local gears = require("gears")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

-- Color Palettes
-- Palette mirrors sway/config + waybar/style.css (gruvbox-dark)
local palettes = {
	["gruvbox"] = {
		fg_normal = "#FBF1C7",
		fg_focus = "#32302F",
		fg_urgent = "#EBDBB2",
		bg_normal = "#1D2021",
		bg_focus = "#5a633a", -- dark_green_hard, matches tasklist_fg_normal
		bg_urgent = "#9D0006", -- sway client.urgent / waybar workspace urgent
		border_width = dpi(2), -- sway: default_border pixel 2
		border_normal = "#504945", -- dark2; sway client.unfocused
		border_focus = "#FE8019", -- sway client.focused
		border_marked = "#9D0006",
		powerline_spr1 = "#792329", -- dark_red_hard
		powerline_spr2 = "#d3869b", -- bright_purple; naughty low-urgency border
		tasklist_fg_focus = "#B8BB26",
		tasklist_fg_normal = "#5A633A",
		-- waybar per-module backgrounds (waybar/style.css)
		mod_cpu = "#fb4934",
		mod_mem = "#fe8019",
		mod_backlight = "#fabd2f",
		mod_volume = "#b8bb26",
		mod_battery = "#8ec07c",
		-- waybar reuses #8ec07c for the clock, but there it sits in
		-- modules-center, away from the battery. Here they are adjacent, so the
		-- clock takes waybar's otherwise unused #mpris blue.
		mod_date = "#83a598",
		-- waybar's tray bg (#1d2021) matches bg_normal, invisible here since
		-- the tray sits between two powerline arrows (waybar's doesn't).
		-- Reuse powerline_spr1 so both arrows around it stay high-contrast.
		mod_tray = "#792329",
		-- waybar workspace states
		taglist_bg_focus = "#689d6a",
		taglist_fg_focus_sel = "#1d2021",
	},
}

local os = os
local active_palette = palettes["gruvbox"]

local theme = {
	fg_normal = active_palette.fg_normal,
	fg_focus = active_palette.fg_focus,
	fg_urgent = active_palette.fg_urgent,
	bg_normal = active_palette.bg_normal,
	bg_focus = active_palette.bg_focus,
	bg_urgent = active_palette.bg_urgent,
	border_normal = active_palette.border_normal,
	border_focus = active_palette.border_focus,
	border_marked = active_palette.border_marked,
	powerline_spr1 = active_palette.powerline_spr1,
	powerline_spr2 = active_palette.powerline_spr2,
	tasklist_fg_focus = active_palette.tasklist_fg_focus,
	tasklist_fg_normal = active_palette.tasklist_fg_normal,
	mod_cpu = active_palette.mod_cpu,
	mod_mem = active_palette.mod_mem,
	mod_backlight = active_palette.mod_backlight,
	mod_volume = active_palette.mod_volume,
	mod_battery = active_palette.mod_battery,
	mod_date = active_palette.mod_date,
	mod_tray = active_palette.mod_tray,
}

theme.dir = os.getenv("HOME") .. "/.config/awesome"
-- Wallpaper is owned by wallpaper.lua (per-tag, via gears.wallpaper), not by
-- an external tool or theme.wallpaper.
theme.font = "NotoSans Nerd Font 10" -- waybar: 12.5px
theme.border_width = active_palette.border_width
theme.bar_height = dpi(26) -- waybar is 24; slightly taller for a bit more breathing room
-- No floating margin: picom can't clip blur/opacity to only the bar's visible
-- shape (upstream limitation, see picom#567), so a transparent gap around the
-- bar gets blurred/washed out too. Flush bar avoids that gap entirely.
theme.bar_margin = dpi(0)
theme.bar_radius = dpi(0)
theme.bg_systray = active_palette.mod_tray
-- 0 (awesome's own default) is the only value systray:fit()/:draw() agree on
-- for any icon count -- non-zero spacing here + set_base_size() together
-- causes draw() to overflow past what fit() reserved (confirmed upstream
-- widget quirk, not something this config can safely work around otherwise).
theme.systray_icon_spacing = 0
theme.tasklist_align = "center"
theme.tasklist_bg_focus = theme.bg_normal
theme.tasklist_font = theme.font

-- Taglist (waybar sway/workspaces styling)
theme.taglist_bg_focus = active_palette.taglist_bg_focus
theme.taglist_fg_focus = active_palette.taglist_fg_focus_sel
theme.taglist_bg_urgent = active_palette.bg_urgent
theme.taglist_fg_urgent = active_palette.fg_urgent
theme.taglist_spacing = dpi(8) -- waybar workspace buttons are spaced apart

theme.menu_height = dpi(20)
theme.menu_width = dpi(160)
theme.menu_submenu_icon = theme.dir .. "/icons/submenu.png"
theme.layout_tile = theme.dir .. "/icons/tile.png"
theme.layout_tileleft = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv = theme.dir .. "/icons/fairv.png"
theme.layout_fairh = theme.dir .. "/icons/fairh.png"
theme.layout_spiral = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle = theme.dir .. "/icons/dwindle.png"
theme.layout_max = theme.dir .. "/icons/max.png"
theme.layout_fullscreen = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier = theme.dir .. "/icons/magnifier.png"
theme.layout_floating = theme.dir .. "/icons/floating.png"
theme.widget_ac = theme.dir .. "/icons/ac.png"
theme.widget_battery = theme.dir .. "/icons/battery.png"
theme.widget_battery_low = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty = theme.dir .. "/icons/battery_empty.png"
theme.widget_mem = theme.dir .. "/icons/mem.png"
theme.widget_cpu = theme.dir .. "/icons/cpu.png"
theme.widget_temp = theme.dir .. "/icons/temp.png"
theme.widget_net = theme.dir .. "/icons/net.png"
theme.widget_hdd = theme.dir .. "/icons/hdd.png"
theme.widget_vol = theme.dir .. "/icons/vol.png"
theme.widget_vol_low = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute = theme.dir .. "/icons/vol_mute.png"
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = dpi(4) -- sway: gaps inner/outer 4
theme.gap_single_client = true

-- Notification defaults — mirrors mako/config
naughty.config.defaults.ontop = true
naughty.config.defaults.icon_size = dpi(32) -- mako max-icon-size=32
naughty.config.defaults.timeout = 4 -- mako default-timeout=4000
naughty.config.defaults.hover_timeout = 300
naughty.config.defaults.margin = dpi(8) -- mako padding=8
naughty.config.defaults.border_width = dpi(1) -- mako border-size=1
naughty.config.defaults.border_color = active_palette.powerline_spr1 -- mako border-color=#722529
naughty.config.defaults.position = "top_right" -- mako anchor=top-right
naughty.config.defaults.font = theme.font
naughty.config.defaults.fg = theme.fg_normal
naughty.config.defaults.bg = theme.bg_normal
naughty.config.defaults.shape = function(cr, w, h)
	gears.shape.rounded_rect(cr, w, h, dpi(0)) -- mako border-radius=0
end

-- mako [urgency=critical]: bg #722529, border #B8BB26, no timeout
naughty.config.presets.critical = {
	bg = "#722529",
	fg = theme.fg_normal,
	border_color = "#B8BB26",
	timeout = 0,
}
-- mako [urgency=low]: border #49503B
naughty.config.presets.low = {
	bg = theme.bg_normal,
	fg = theme.fg_normal,
	border_color = active_palette.powerline_spr2,
	timeout = 4,
}

return theme
