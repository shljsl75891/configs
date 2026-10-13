local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")

screen.connect_signal("arrange", function(s)
	local only_one = #s.tiled_clients == 1
	for _, c in pairs(s.clients) do
		if only_one and not c.floating or c.maximized or c.fullscreen then
			c.border_width = 0
		else
			c.border_width = beautiful.border_width
		end
	end
end)

client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end
	c.shape = function(cr, w, h)
		gears.shape.rounded_rect(cr, w, h, 0)
	end

	if
		awesome.startup
		and not c.size_hints.user_position
		and not c.size_hints.program_position
	then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

-- Enable sloppy focus, so that focus follows mouse.
--[[ client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = vi_focus })
end) ]]

client.connect_signal("focus", function(c)
	if not c.ontop then
		c.border_color = beautiful.border_focus
	end
end)
client.connect_signal("unfocus", function(c)
	if not c.ontop then
		c.border_color = beautiful.border_normal
	end
end)

-- switch to parent after closing child window
local function backham()
	local s = awful.screen.focused()
	local c = awful.client.focus.history.get(s, 0)
	if c then
		client.focus = c
		c:raise()
	end
end

-- attach to minimized state
client.connect_signal("property::minimized", backham)
-- attach to closed state
client.connect_signal("unmanage", backham)
-- ensure there is always a selected client during tag switching or logins
tag.connect_signal("property::selected", backham)
