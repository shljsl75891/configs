local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local theme = require("ui.theme")

local bluetooth = require("ui.widgets.bluetooth")
local clock = require("ui.widgets.clock")
local punch = require("ui.widgets.punch")
local vars = require("config.vars")
local buttons = require("config.buttons")

local markup = lain.util.markup
local separators = lain.util.separators

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
	awful.tag(vars.tagnames, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(
		s,
		awful.widget.taglist.filter.all,
		buttons.taglist
	)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(
		s,
		awful.widget.tasklist.filter.currenttags,
		buttons.tasklist
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
			timeout = 3,
			width = 40,
			step_width = 2,
			step_spacing = 0,
			color = theme.bg_normal,
		}),
		volume = require("awesome-wm-widgets.volume-widget.volume")({
			widget_type = "icon_and_text",
			card = 0,
			device = "pulse", -- needs libasound2-plugins; routes amixer to PipeWire default sink
			mixctrl = "Master",
			step = 5,
			refresh_rate = 10,
			-- A known widget_type gets the top-level args table verbatim
			-- (icon_and_text_args only applies to the unknown-type fallback).
			font = theme.font,
			icon_dir = icon_base_path,
		}),
		battery = require("awesome-wm-widgets.battery-widget.battery")({
			show_current_level = true,
			path_to_icons = icon_base_path,
			timeout = 30,
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

	-- Buttons go on the padded module so a click on the padding also works.
	local bluetooth_module = module(bluetooth.widget, theme.mod_bluetooth)
	bluetooth_module:buttons(bluetooth.buttons)

	local punch_part = {
		box = module(punch.widget, theme.bg_urgent),
		arrow = arrow(theme.mod_date, theme.bg_urgent),
	}
	table.insert(punch.boxes, punch_part)

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
					arrow(theme.mod_volume, theme.mod_bluetooth),
					bluetooth_module,
					arrow(theme.mod_bluetooth, theme.mod_battery),
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
