local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local theme = require("./theme")
local theme_assets = require("beautiful.theme_assets")

local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

-- Generate taglist squares:
local taglist_square_size = dpi(0)
theme.taglist_squares_sel = theme_assets.taglist_squares_unsel(
	taglist_square_size,
	theme.dir .. "/icons/square_sel.png"
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
	taglist_square_size,
	theme.dir .. "/icons/square_unsel.png"
)

local markup = lain.util.markup
local separators = lain.util.separators

-- Textclock
local clock = awful.widget.watch(
	"date +'%a %b %d, %I:%M %p'",
	30,
	function(widget, stdout)
		widget:set_markup(" " .. markup.font(theme.font, stdout))
	end
)

-- Calendar
theme.cal = lain.widget.cal({
	attach_to = { clock },
	three = true,
	week_start = 1, -- Sunday
	notification_preset = {
		font = "TX02 Nerd Font 9",
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	},
})

-- MEM
local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
	settings = function()
		widget:set_markup(
			markup.font(
				theme.font,
				" " .. string.format("%.2f", mem_now.used / 1024) .. "GB "
			)
		)
	end,
})

-- Net
local net = lain.widget.net({
	settings = function()
		widget:set_markup(
			markup.font(
				theme.font,
				markup(
					theme.fg_normal,
					"  " .. string.format("%0.1f", net_now.sent / 1024) .. "MB/s "
				)
					.. " "
					.. markup(
						theme.fg_normal,
						"  "
							.. string.format("%0.1f", net_now.received / 1024)
							.. "MB/s "
					)
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
	s.mytaglist = awful.widget.taglist(
		s,
		awful.widget.taglist.filter.all,
		awful.util.taglist_buttons
	)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(
		s,
		awful.widget.tasklist.filter.currenttags,
		awful.util.tasklist_buttons
	)
	-- s.mytasklist = nil

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = dpi(18),
		border_width = dpi(1),
		bg = theme.bg_normal,
		fg = theme.fg_normal,
		opacity = 0.9,
		shape = function(cr, w, h)
			gears.shape.rounded_rect(cr, w, h, dpi(0))
		end,
	})

	-- Separators
	local spr = wibox.widget.textbox(" ")
	local arrow = separators.arrow_left
	local systray = wibox.widget.systray()
	-- widgets
	local widgets = {
		cpu = require("awesome-wm-widgets.cpu-widget.cpu-widget")({
			width = 25,
			step_width = 2,
			step_spacing = 0,
			color = theme.fg_normal,
		}),
		volume = require("awesome-wm-widgets.volume-widget.volume")({
			card = 0,
			widget_type = "horizontal_bar",
			device = "default",
			with_icon = true,
			margins = 7,
			shape = "octagon",
			bg_color = "#1F2335",
			mute_color = theme.bg_urgent,
		}),
		battery = require("awesome-wm-widgets.battery-widget.battery")({
			show_current_level = true,
			timeout = 2,
			path_to_icons = "/home/sahil.jassal/.icons/Rose-Pine/status/symbolic/",
			font = theme.font,
		}),
		brightness = require("awesome-wm-widgets.brightness-widget.brightness")({
			type = "icon_and_text",
			percentage = true,
			timeout = 100,
			path_to_icon = "/home/sahil.jassal/.icons/Rose-Pine/status/symbolic/display-brightness-medium-symbolic.svg",
			program = "xbacklight",
			base = 5,
			step = 10,
		}),
		todo = require("awesome-wm-widgets.todo-widget.todo")(),
	}

	local function create_powerline_widget(widget, bg_color, margin_x, margin_y)
		return wibox.container.background(
			wibox.container.margin(
				wibox.widget({ widget, layout = wibox.layout.align.horizontal }),
				dpi(margin_x or 2),
				dpi(margin_y or 3)
			),
			bg_color
		)
	end

	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		-- Left widgets
		{ layout = wibox.layout.fixed.horizontal, s.mytaglist, s.mypromptbox, spr },
		-- Middle widget (Tasklist)
		s.mytasklist,
		-- Right widgets
		{
			layout = wibox.layout.fixed.horizontal,
			arrow(theme.bg_normal, theme.powerline_spr1),
			create_powerline_widget(net.widget, theme.powerline_spr1),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			create_powerline_widget(
				wibox.widget.textbox("󰍛 "),
				theme.powerline_spr2
			),
			create_powerline_widget(mem.widget, theme.powerline_spr2),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			create_powerline_widget(widgets.cpu, theme.powerline_spr1),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			create_powerline_widget(widgets.volume, theme.powerline_spr2),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			create_powerline_widget(widgets.battery, theme.powerline_spr1),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			create_powerline_widget(widgets.brightness, theme.powerline_spr2),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			systray,
			create_powerline_widget(clock, theme.powerline_spr1, 3, 8),
			arrow(theme.powerline_spr1, theme.powerline_spr2),
			arrow(theme.powerline_spr2, theme.powerline_spr1),
			create_powerline_widget(widgets.todo, theme.powerline_spr1),
		},
	})
end

return theme
