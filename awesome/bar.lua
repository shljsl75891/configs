local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local theme = require("./theme")
local theme_assets = require("beautiful.theme_assets")

local my_table = gears.table

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

-- Textclock — waybar custom/date: "Mon DD Month YYYY HH:MM AM/PM"
local clock =
	awful.widget.watch("date +'%a %d %b %I:%M %p'", 5, function(widget, stdout)
		widget:set_markup(markup.font(theme.font, (stdout:gsub("\n", ""))))
	end)

-- PeopleStrong attendance: red, then orange after punch in, yellow after punch out. Left-click punches.
local punch_cmd = theme.dir .. "/scripts/peoplestrong/mark-attendance"
local ICON = "󱑆"
local ARROWS = ""
-- The bar parts of the widget, one set per screen, so the state can recolor them.
local punch_boxes = {}

--- Widget text and colors for the `mark-attendance status` output.
-- Red: no punch today (--→--), or the user must act (login?, offline, busy, error).
-- Orange: punched in, waiting for the end of the shift. Yellow: punched out.
local function punch_state(status)
	local from, to = status:match("^(%d%d:%d%d)→(.*)$")
	if not from then
		return "Attendance", theme.bg_urgent, theme.fg_urgent
	elseif to:match("^%d%d:%d%d$") then
		return from .. "  " .. ARROWS .. "  " .. to, theme.mod_backlight, theme.bg_normal
	end
	return from, theme.mod_mem, theme.bg_normal
end

local punch, punch_timer = awful.widget.watch(punch_cmd .. " status", 300, function(widget, stdout)
	local text, bg, fg = punch_state(stdout:gsub("\n", ""))
	widget:set_markup(markup.font(theme.font, ICON .. " " .. text))
	for _, part in ipairs(punch_boxes) do
		part.box.bg = bg
		part.box.fg = fg
		part.arrow.update(theme.mod_date, bg)
	end
end)
punch:set_markup(markup.font(theme.font, ICON .. " …"))
punch:buttons(awful.button({}, 1, function()
	-- The click's own output is only a notification; re-run the status check instead.
	awful.spawn.easy_async(punch_cmd, function()
		punch_timer:emit_signal("timeout")
	end)
end))

-- Calendar — waybar date tooltip runs `ncal -C -3`, lain.cal three=true matches
theme.cal = lain.widget.cal({
	attach_to = { clock },
	three = true,
	week_start = 1,
	notification_preset = {
		position = "top_right",
		font = "TX02 Nerd Font 9",
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	},
})

-- MEM — waybar: "  {used:0.1f}GB"
local mem = lain.widget.mem({
	timeout = 10,
	settings = function()
		widget:set_markup(
			markup.font(
				theme.font,
				"  " .. string.format("%.1f", mem_now.used / 1024) .. "GB"
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

	-- Create the wibox
	-- Flush bar (bar_margin=0): picom's blur/opacity on this dock window can't
	-- be clipped to the visible rounded shape, so any transparent margin here
	-- would get blurred/washed out too (see theme.lua for details). The inner
	-- rounded background below still gives corner rounding via bar_radius.
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = theme.bar_height + 2 * theme.bar_margin,
		bg = "#00000000",
		fg = theme.fg_normal,
	})

	-- Separators
	local spr = wibox.widget.textbox(" ")
	local arrow = separators.arrow_left
	local systray = wibox.widget.systray()
	-- theme.systray_icon_spacing must stay 0: non-zero spacing makes
	-- systray:draw() overflow past what :fit() reserved (upstream quirk).
	-- Bigger icons make up the breathing room instead. No forced_width:
	-- fit() is accurate at spacing=0, so it sizes itself correctly.
	systray:set_base_size(dpi(19))
	local systray_wrapped = wibox.widget({
		systray,
		valign = "center",
		widget = wibox.container.place,
	})
	-- Local copies of Gruvbox-Dark's symbolic icons, refilled #1d2021 so they
	-- read on the bright waybar module colours. imagebox draws an SVG's own
	-- fill verbatim -- unlike waybar, whose icons are recolourable font glyphs.
	local icon_base_path = theme.dir .. "/icons/status/"

	-- widgets
	local widgets = {
		cpu = require("awesome-wm-widgets.cpu-widget.cpu-widget")({
			width = 40,
			step_width = 2,
			step_spacing = 0,
			color = theme.bg_normal,
		}),
		volume = require("awesome-wm-widgets.volume-widget.volume")({
			widget_type = "icon_and_text",
			card = 0,
			device = "default", -- 'pulse' needs libasound2-plugins; 'default' works
			mixctrl = "Master",
			step = 5,
			-- A known widget_type gets the top-level args table verbatim
			-- (icon_and_text_args only applies to the unknown-type fallback).
			font = theme.font,
			icon_dir = icon_base_path,
		}),
		battery = require("awesome-wm-widgets.battery-widget.battery")({
			show_current_level = true,
			timeout = 25,
			path_to_icons = icon_base_path,
			font = theme.font,
		}),
		brightness = require("awesome-wm-widgets.brightness-widget.brightness")({
			type = "icon_and_text",
			percentage = true,
			timeout = 10,
			path_to_icon = icon_base_path .. "display-brightness-medium-symbolic.svg",
			program = "brightnessctl", -- same binary sway binds XF86MonBrightness to
			base = 5,
			step = 5, -- sway: brightnessctl set +5% / 5%-
			rmb_set_max = true,
		}),
	}

	-- volume-widget strips the '%' before display (amixer output also feeds
	-- tonumber() for icon-threshold selection, so the submodule can't just
	-- append it). Wrap the constructed widget from our own config instead of
	-- patching the vendored file: call the original setter first (keeps icon
	-- + mute logic intact), then append '%' to whatever text it just set.
	do
		local orig_set_volume_level = widgets.volume.set_volume_level
		widgets.volume.set_volume_level = function(self, new_value)
			orig_set_volume_level(self, new_value)
			local txt = self:get_children_by_id("txt")[1]
			if txt then
				txt:set_text(txt.text .. "%")
			end
		end
	end

	-- Background + padding wrapper; fg defaults to dark so text stays legible
	-- on waybar's bright module colours.
	local function module(widget, bg_color, fg_color, margin_x, margin_y)
		local container = wibox.container.background(
			wibox.container.margin(
				wibox.widget({ widget, layout = wibox.layout.align.horizontal }),
				dpi(margin_x or 4),
				dpi(margin_y or 4)
			),
			bg_color
		)
		container.fg = fg_color or theme.bg_normal
		return container
	end

	local punch_part = {
		box = module(punch, theme.bg_urgent),
		arrow = arrow(theme.mod_date, theme.bg_urgent),
	}
	table.insert(punch_boxes, punch_part)

	s.mywibox:setup({
		widget = wibox.container.margin,
		margins = theme.bar_margin,
		{
			widget = wibox.container.background,
			bg = theme.bg_normal,
			shape = function(cr, w, h)
				gears.shape.rounded_rect(cr, w, h, theme.bar_radius)
			end,
			{
				layout = wibox.layout.align.horizontal,
				-- Left widgets
				{
					layout = wibox.layout.fixed.horizontal,
					s.mytaglist,
					s.mypromptbox,
					spr,
				},
				-- Middle widget (Tasklist)
				s.mytasklist,
				-- Right widgets — waybar module order: cpu, memory, backlight,
				-- pulseaudio, battery, tray; clock kept from awesome.
				{
					layout = wibox.layout.fixed.horizontal,
					arrow(theme.bg_normal, theme.mod_cpu),
					module(widgets.cpu, theme.mod_cpu),
					arrow(theme.mod_cpu, theme.mod_mem),
					module(mem.widget, theme.mod_mem),
					arrow(theme.mod_mem, theme.mod_backlight),
					module(widgets.brightness, theme.mod_backlight),
					arrow(theme.mod_backlight, theme.mod_volume),
					module(widgets.volume, theme.mod_volume),
					arrow(theme.mod_volume, theme.mod_battery),
					module(widgets.battery, theme.mod_battery),
					arrow(theme.mod_battery, theme.mod_tray),
					module(systray_wrapped, theme.mod_tray, theme.fg_normal),
					arrow(theme.mod_tray, theme.mod_date),
					module(clock, theme.mod_date),
					punch_part.arrow,
					punch_part.box,
				},
			},
		},
	})
end

return theme
