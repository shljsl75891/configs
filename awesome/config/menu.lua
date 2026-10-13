local awful = require("awful")
local beautiful = require("beautiful")
local freedesktop = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
local vars = require("config.vars")

local terminal, editor = vars.terminal, vars.editor

-- Create a launcher widget and a main menu
local myawesomemenu = {
	{
		"Hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "Manual", string.format("%s -e man awesome", terminal) },
	{
		"Edit config",
		string.format("%s -e %s %s", terminal, editor, awesome.conffile),
	},
	{ "Restart", awesome.restart },
	{
		"Quit",
		function()
			awesome.quit()
		end,
	},
}

return freedesktop.menu.build({
	before = {
		{ "Awesome", myawesomemenu, beautiful.awesome_icon },
		-- other triads can be put here
	},
	after = {
		{ "Open terminal", terminal },
		-- other triads can be put here
	},
})
