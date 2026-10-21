local awful = require("awful")
local beautiful = require("beautiful")
local vars = require("config.vars")
local buttons = require("config.buttons")
local clientkeys = require("config.keys").client

local tagnames = vars.tagnames

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		callback = awful.client.setslave,
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = buttons.client,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
			size_hints_honor = false,
		},
	},

	-- Floating clients — sway/config: `for_window [floating] move position center`
	{
		rule_any = {
			instance = { "pinentry" },
			role = { "pop-up" },
			type = { "dialog" },
		},
		properties = { floating = true, placement = awful.placement.centered },
	},

	-- sway: `for_window [app_id="pcmanfm"] floating enable, resize set 800 600`
	{
		rule = { class = "Pcmanfm" },
		properties = {
			floating = true,
			width = 800,
			height = 600,
			placement = awful.placement.centered,
		},
	},

	-- sway: `for_window [app_id="com.github.hluk.copyq"] floating enable, resize set 700 500`
	{
		rule_any = { class = { "copyq" }, instance = { "copyq" } },
		properties = {
			floating = true,
			width = 700,
			height = 500,
			placement = awful.placement.centered,
		},
	},

	-- Workspace assignments — sway/config: assign obsidian -> 4, slack -> 7
	{
		rule = { class = "obsidian" },
		properties = { screen = 1, tag = tagnames[4] },
	},
	{
		rule = { class = "slack" },
		properties = { screen = 1, tag = tagnames[7] },
	},
}

