local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
local vars = require("config.vars")

local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local brightness_widget =
	require("awesome-wm-widgets.brightness-widget.brightness")

local mytable = require("gears").table
local modkey, altkey, terminal, browser =
	vars.modkey, vars.altkey, vars.terminal, vars.browser

local globalkeys = mytable.join(
	-- Destroy all notifications
	awful.key({ modkey }, "BackSpace", function()
		naughty.destroy_all_notifications()
	end, { description = "destroy all notifications", group = "hotkeys" }),

	-- Show help ($mod+s is the screenshot bind in sway, so help moves to F1)
	awful.key(
		{ modkey },
		"F1",
		hotkeys_popup.show_help,
		{ description = "show help", group = "awesome" }
	),

	-- Layout manipulation
	awful.key(
		{ modkey },
		"=",
		function()
			awful.tag.incnmaster(1, nil, true)
		end,
		{ description = "increase the number of master clients", group = "layout" }
	),
	awful.key(
		{ modkey },
		"-",
		function()
			awful.tag.incnmaster(-1, nil, true)
		end,
		{ description = "decrease the number of master clients", group = "layout" }
	),
	awful.key({ modkey, "Control" }, "=", function()
		awful.tag.incncol(1, nil, true)
	end, { description = "increase the number of columns", group = "layout" }),
	awful.key({ modkey, "Control" }, "-", function()
		awful.tag.incncol(-1, nil, true)
	end, { description = "decrease the number of columns", group = "layout" }),
	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),
	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),
	awful.key(
		{ modkey },
		"u",
		awful.client.urgent.jumpto,
		{ description = "jump to urgent client", group = "client" }
	),
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.byidx(1)
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus next window in tag", group = "client" }),
	awful.key({ modkey, "Shift" }, "Tab", function()
		awful.client.focus.byidx(-1)
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus previous window in tag", group = "client" }),

	-- Show/hide wibox
	awful.key({ modkey }, "x", function()
		for s in screen do
			s.mywibox.visible = not s.mywibox.visible
		end
	end, { description = "toggle wibox", group = "awesome" }),

	-- Launching Programs
	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end, { description = "open a terminal", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "r", awesome.restart, {
		description = "reload awesome",
		group = "awesome",
	}),
	awful.key({ modkey, "Shift" }, "q", function()
		awful.prompt.run({
			prompt = "Exit awesome? [y/N] ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = function(input)
				if input:lower() == "y" then
					awesome.quit()
				end
			end,
		})
	end, { description = "quit awesome", group = "awesome" }),
	awful.key({ modkey }, "s", function()
		awful.spawn({
			"bash",
			"-c",
			"set -o pipefail; maim -o -s | xclip -selection clipboard -t image/png"
				.. " && notify-send Screenshot 'Copied to clipboard'",
		})
	end, { description = "screenshot region to clipboard", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "s", function()
		awful.spawn.with_shell("~/.config/awesome/scripts/recording.sh")
	end, { description = "toggle screen recording", group = "launcher" }),
	awful.key({ modkey }, "e", function()
		awful.spawn("pcmanfm")
	end, { description = "open a explorer", group = "launcher" }),
	awful.key({ modkey }, "p", function()
		awful.spawn("copyq toggle")
	end, { description = "toggle clipboard manager", group = "launcher" }),
	-- Voice dictation — sway parity (needs `ydotool` + `ydotoold` on X11)
	awful.key({ modkey }, "d", function()
		awful.spawn("hyprvoice toggle")
	end, { description = "toggle voice dictation", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "d", function()
		awful.spawn("hyprvoice cancel")
	end, { description = "cancel voice dictation", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "l", function()
		awful.spawn("slock")
	end, { description = "lock screen", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "o", function()
		awful.spawn("obsidian")
	end, {
		description = "launch the note taking app - Obsidian",
		group = "launcher",
	}),
	awful.key({ modkey }, "b", function()
		awful.spawn(browser .. " --profile-directory='Profile 2'")
	end, {
		description = "launch brave browser with work profile",
		group = "launcher",
	}),
	awful.key({ modkey, "Shift" }, "b", function()
		awful.spawn(browser .. " --profile-directory='Profile 1'")
	end, {
		description = "launch brave browser with personal profile",
		group = "launcher",
	}),
	awful.key({ modkey, "Shift" }, "n", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			c:emit_signal("request::activate", "key.unminimize", { raise = true })
		end
	end, { description = "restore minimized", group = "client" }),

	-- Screen brightness
	awful.key({}, "XF86MonBrightnessUp", function()
		brightness_widget:inc()
	end, { description = "+5%", group = "hotkeys" }),
	awful.key({}, "XF86MonBrightnessDown", function()
		brightness_widget:dec()
	end, { description = "-5%", group = "hotkeys" }),

	-- ALSA volume control
	awful.key({}, "XF86AudioRaiseVolume", function()
		volume_widget.inc()
	end, { description = "volume up", group = "hotkeys" }),
	awful.key({}, "XF86AudioLowerVolume", function()
		volume_widget.dec()
	end, { description = "volume down", group = "hotkeys" }),
	awful.key({}, "XF86AudioMute", function()
		volume_widget.toggle()
	end, { description = "toggle mute", group = "hotkeys" }),

	-- dmenu — colours/font mirror sway/scripts/launcher.sh (wmenu-run)
	awful.key({ modkey }, "r", function()
		awful.spawn.with_shell(
			"dmenu_run -i -fn 'NotoSans Nerd Font-10'"
				.. " -nb '#1d2021' -nf '#d4be98' -sb '#689d6a' -sf '#1d2021'"
		)
	end, { description = "show dmenu", group = "launcher" })
)

for key, direction in pairs({ j = "down", k = "up", h = "left", l = "right" }) do
	globalkeys = mytable.join(
		globalkeys,
		awful.key({ modkey }, key, function()
			awful.client.focus.global_bydirection(direction)
			if client.focus then
				client.focus:raise()
			end
		end, { description = "focus " .. direction, group = "client" })
	)
end

local clientkeys = mytable.join(
	-- Resize windows
	awful.key({ modkey }, "Up", function(c)
		if c.floating then
			c:relative_move(0, 0, 0, 50)
		else
			awful.client.incwfact(0.1)
		end
	end, { description = "Window Resize Taller", group = "client" }),
	awful.key({ modkey }, "Down", function(c)
		if c.floating then
			c:relative_move(0, 0, 0, -50)
		else
			awful.client.incwfact(-0.1)
		end
	end, { description = "Window Resize Shorter", group = "client" }),
	awful.key({ modkey }, "Left", function(c)
		if c.floating then
			c:relative_move(0, 0, -50, 0)
		else
			awful.tag.incmwfact(-0.05)
		end
	end, { description = "Window Resize Horizontal -", group = "client" }),
	awful.key({ modkey }, "Right", function(c)
		if c.floating then
			c:relative_move(0, 0, 50, 0)
		else
			awful.tag.incmwfact(0.05)
		end
	end, { description = "Window Resize Horizontal +", group = "client" }),

	-- Move Floating Windows
	awful.key({ altkey }, "Down", function(c)
		c:relative_move(0, 50, 0, 0)
	end, { description = "Move Floating Window Down", group = "floating-client" }),
	awful.key({ altkey }, "Up", function(c)
		c:relative_move(0, -50, 0, 0)
	end, { description = "Move Floating Window Up", group = "floating-client" }),
	awful.key({ altkey }, "Left", function(c)
		c:relative_move(-50, 0, 0, 0)
	end, { description = "Move Floating Window Left", group = "floating-client" }),
	awful.key(
		{ altkey },
		"Right",
		function(c)
			c:relative_move(50, 0, 0, 0)
		end,
		{ description = "Move Floating Window Right", group = "floating-client" }
	),
	awful.key({ modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),
	awful.key({ modkey }, "q", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ modkey },
		"o",
		awful.client.floating.toggle,
		{ description = "toggle floating window", group = "floating-client" }
	),
	awful.key({ modkey, "Shift" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),
	-- sway binds $mod+t to sticky; ontop moves to $mod+Shift+t
	awful.key({ modkey }, "t", function(c)
		c.sticky = not c.sticky
	end, { description = "toggle sticky", group = "client" }),
	awful.key({ modkey, "Shift" }, "t", function(c)
		c.ontop = not c.ontop
		if c.ontop then
			c.border_color = beautiful.bg_urgent
		else
			if client.focus == c then
				c.border_color = beautiful.border_focus
			else
				c.border_color = beautiful.border_normal
			end
		end
	end, { description = "toggle always on top", group = "client" }),
	awful.key({ modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, { description = "minimize", group = "client" }),
	awful.key({ modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, { description = "(un)maximize", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = mytable.join(
		globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),
		-- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, { description = "toggle tag #" .. i, group = "tag" }),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" }),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, { description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

return { global = globalkeys, client = clientkeys }
