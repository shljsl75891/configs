local awful = require("awful")
local lain = require("lain")
local theme = require("ui.theme")

local markup = lain.util.markup

-- Textclock — waybar custom/date: "Mon DD Month YYYY HH:MM AM/PM"
local clock =
	awful.widget.watch("date +'%a %d %b %I:%M %p'", 5, function(widget, stdout)
		widget:set_markup(markup.font(theme.font, (stdout:gsub("\n", ""))))
	end)

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


return clock
