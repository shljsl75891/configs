local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local theme_assets = require("beautiful.theme_assets")

-- widgets
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
local brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")

local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme = {}
theme.dir = os.getenv("HOME") .. "/.config/awesome"
theme.wallpaper = theme.dir .. "/wall.png"
theme.font = "Ubuntu Nerd Font Medium 8"
theme.fg_normal = "#FBF1C7"
theme.fg_focus = "#32302F"
theme.fg_urgent = "#FBF1C7"
theme.bg_normal = "#1D2021"
theme.bg_focus = "#62693E"
theme.bg_urgent = "#722529"
theme.border_width = dpi(2)
theme.border_normal = "#1A1B26"
theme.border_focus = "#689D6A"
theme.border_marked = "#CC9393"
theme.powerline_spr1 = "#722529"
theme.powerline_spr2 = "#49503B"
theme.bg_systray = theme.powerline_spr1
theme.tasklist_align = "center"
theme.tasklist_bg_focus = theme.bg_normal
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
theme.titlebar_close_button_focus = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

-- Generate taglist squares:
local taglist_square_size = dpi(0)
theme.taglist_squares_sel =
	theme_assets.taglist_squares_unsel(taglist_square_size, theme.dir .. "/icons/square_sel.png")
theme.taglist_squares_unsel =
	theme_assets.taglist_squares_unsel(taglist_square_size, theme.dir .. "/icons/square_unsel.png")

local markup = lain.util.markup
local separators = lain.util.separators

-- Textclock
local clock = awful.widget.watch("date +'%a %b %d, %I:%M %p'", 60, function(widget, stdout)
	widget:set_markup(" " .. markup.font(theme.font, stdout))
end)

-- Calendar
theme.cal = lain.widget.cal({
	attach_to = { clock },
	notification_preset = {
		font = "UbuntuMono Nerd Font 9",
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	},
})

-- MEM
local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
	settings = function()
		widget:set_markup(markup.font(theme.font, " " .. string.format("%.2f", mem_now.used / 1024) .. "GB "))
	end,
})

-- Net
local net = lain.widget.net({
	settings = function()
		widget:set_markup(
			markup.font(
				theme.font,
				markup(theme.fg_normal, "  " .. string.format("%0.1f", net_now.sent / 1024) .. "MB/s ")
					.. " "
					.. markup(theme.fg_normal, "  " .. string.format("%0.1f", net_now.received / 1024) .. "MB/s ")
			)
		)
	end,
})

function theme.at_screen_connect(s)
	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 2, function()
			awful.layout.set(awful.layout.layouts[1])
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

	-- Create a tasklist widget
	-- s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)
	s.mytasklist = nil

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = dpi(20),
		border_width = dpi(2),
		bg = theme.bg_normal,
		fg = theme.fg_normal,
		opacity = 0.9,
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, 8)
		end,
	})

	-- Separators
	local spr = wibox.widget.textbox(" ")
	local arrow = separators.arrow_left
	local systray = wibox.widget.systray()

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			--spr,
			s.mytaglist,
			s.mypromptbox,
			spr,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			arrow(theme.bg_normal, theme.powerline_spr1),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ net.widget, layout = wibox.layout.align.horizontal }),
					dpi(2),
					dpi(3)
				),
				theme.powerline_spr1
			),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			wibox.container.background(wibox.widget.textbox("󰍛 "), theme.powerline_spr2),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({ mem.widget, layout = wibox.layout.align.horizontal }),
					dpi(2),
					dpi(3)
				),
				theme.powerline_spr2
			),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({
						cpu_widget({
							width = 25,
							step_width = 2,
							step_spacing = 0,
							color = theme.fg_normal,
						}),
						layout = wibox.layout.align.horizontal,
					}),
					dpi(2),
					dpi(3)
				),
				theme.powerline_spr1
			),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({
						volume_widget({
							card = 0,
							widget_type = "horizontal_bar",
							with_icon = true,
							margins = 8,
							shape = "octagon",
							bg_color = "#1f2335",
							mute_color = theme.bg_urgent,
							-- icon_dir = "/home/sahil.jassal/.icons/Gruvbox-Dark/status/symbolic/",
						}),
						layout = wibox.layout.align.horizontal,
					}),
					dpi(2),
					dpi(3)
				),
				theme.powerline_spr2
			),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({
						battery_widget({
							show_current_level = true,
							timeout = 2,
							path_to_icons = "/home/sahil.jassal/.icons/Gruvbox-Dark/status/symbolic/",
							font = theme.font,
						}),
						layout = wibox.layout.align.horizontal,
					}),
					dpi(2),
					dpi(3)
				),
				theme.powerline_spr1
			),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			wibox.container.background(
				brightness_widget({
					type = "icon_and_text",
					percentage = true,
					path_to_icon = "/home/sahil.jassal/.icons/Gruvbox-Dark/status/symbolic/display-brightness-medium-symbolic.svg",
					program = "xbacklight",
					step = 5,
				}),
				theme.powerline_spr2
			),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			systray,
			wibox.container.background(
				wibox.container.margin(
					wibox.widget({
						clock,
						layout = wibox.layout.align.horizontal,
					}),
					dpi(3),
					dpi(8)
				),
				theme.powerline_spr1
			),
		},
	})
end

return theme
