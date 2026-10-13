local awful = require("awful")
local lain = require("lain")
local theme = require("ui.theme")

local markup = lain.util.markup

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
	return from .. "  " .. ARROWS .. "  --", theme.mod_mem, theme.bg_normal
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

return { widget = punch, boxes = punch_boxes }
