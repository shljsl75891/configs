local wibox = require("wibox")
local lain = require("lain")
local theme = require("ui.theme")

local clock = wibox.widget.textclock(
	string.format("<span font='%s'>%%a %%d %%b %%I:%%M %%p</span>", theme.font),
	60
)

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
