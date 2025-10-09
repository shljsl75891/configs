local gears = require("gears")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

-- Color Palettes
-- Define color palettes
local palettes = {
	["gruvbox"] = {
		fg_normal = "#FBF1C7",
		fg_focus = "#32302F",
		fg_urgent = "#FBF1C7",
		bg_normal = "#1D2021",
		bg_focus = "#62693E",
		bg_urgent = "#722529",
		border_width = dpi(2),
		border_normal = "#1A1B26",
		border_focus = "#B8BB26",
		border_marked = "#CC9393",
		powerline_spr1 = "#722529",
		powerline_spr2 = "#49503B",
		tasklist_fg_focus = "#B8BB26",
		tasklist_fg_normal = "#5A633A",
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
}

theme.dir = os.getenv("HOME") .. "/.config/awesome"
theme.wallpaper = theme.dir .. "/wall.png"
theme.font = "NotoSans Nerd Font Medium 7"
theme.border_width = dpi(1)
theme.bg_systray = theme.powerline_spr1
theme.systray_icon_spacing = 3
theme.tasklist_align = "center"
theme.tasklist_bg_focus = theme.bg_normal
theme.tasklist_font = theme.font
theme.titlebar_bg_focus = theme.bg_focus
theme.titlebar_bg_normal = theme.bg_normal
theme.titlebar_fg_focus = theme.fg_focus
theme.menu_height = dpi(16)
theme.menu_width = dpi(140)
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
theme.widget_music = theme.dir .. "/icons/note.png"
theme.widget_music_on = theme.dir .. "/icons/note_on.png"
theme.widget_vol = theme.dir .. "/icons/vol.png"
theme.widget_vol_low = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute = theme.dir .. "/icons/vol_mute.png"
theme.widget_mail = theme.dir .. "/icons/mail.png"
theme.widget_mail_on = theme.dir .. "/icons/mail_on.png"
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = dpi(2)
theme.gap_single_client = true
theme.titlebar_close_button_focus = theme.dir
	.. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal = theme.dir
	.. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active = theme.dir
	.. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = theme.dir
	.. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive = theme.dir
	.. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = theme.dir
	.. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active = theme.dir
	.. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = theme.dir
	.. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive = theme.dir
	.. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = theme.dir
	.. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active = theme.dir
	.. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = theme.dir
	.. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive = theme.dir
	.. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = theme.dir
	.. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active = theme.dir
	.. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = theme.dir
	.. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive = theme.dir
	.. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir
	.. "/icons/titlebar/maximized_normal_inactive.png"

-- Notification Options
naughty.config.defaults.ontop = true
naughty.config.defaults.icon_size = dpi(0)
naughty.config.defaults.timeout = 10
naughty.config.defaults.hover_timeout = 300
naughty.config.defaults.opacity = 0.95
-- naughty.config.defaults.title = "Notifications"
naughty.config.defaults.margin = dpi(8)
naughty.config.defaults.border_width = 0
naughty.config.defaults.border_color = theme.border_normal
naughty.config.defaults.position = "bottom_right"
naughty.config.defaults.shape = function(cr, w, h)
	gears.shape.rounded_rect(cr, w, h, dpi(0))
end

return theme
