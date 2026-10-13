local awful = require("awful")
local beautiful = require("beautiful")
local vars = require("config.vars")
local buttons = require("config.buttons")
local clientkeys = require("config.keys")

local tagnames = vars.tagnames
local target_screen = screen.count() > 1 and 2 or 1

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			callback = awful.client.setslave,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = buttons.client,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
			size_hints_honor = false,
			-- sway/config: `for_window [all] opacity 0.95` (needs picom running)
			opacity = 0.95,
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

	-- Add titlebars to normal clients and dialogs
	{
		rule_any = { type = { "normal", "dialog" } },
		properties = { titlebars_enabled = false },
	},

	-- Workspace assignments — sway/config: assign obsidian -> 4, slack -> 7
	{
		rule = { class = "obsidian" },
		properties = { screen = 1, tag = tagnames[4] },
	},
	{
		rule = { class = "slack" },
		properties = { screen = target_screen, tag = tagnames[7] },
	},
}

