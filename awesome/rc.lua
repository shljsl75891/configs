--[[

     Awesome WM configuration template
     github.com/lcpz

--]]

-- {{{ Required libraries

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local naughty = require("naughty")
--local menubar       = require("menubar")
local freedesktop = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")

-- widgets
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local brightness_widget =
	require("awesome-wm-widgets.brightness-widget.brightness")

require("awful.hotkeys_popup.keys")

local mytable = awful.util.table or gears.table -- 4.{0,1} compatibility
local screen_count = screen.count()
-- }}}

-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

-- Handle runtime errors after startup
do
	local in_error = false

	awesome.connect_signal("debug::error", function(err)
		if in_error then
			return
		end

		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})

		in_error = false
	end)
end

-- }}}

-- {{{ Variable definitions

local modkey = "Mod4"
local altkey = "Mod1"
local terminal = "ghostty"
local editor = os.getenv("EDITOR") or "nvim"
local browser = "brave-origin"

awful.util.terminal = terminal
-- Tag icons mirror waybar sway/workspaces format-icons (waybar/config.jsonc)
local tagnames =
	{ " ", " ", " ", "󰙨 ", "󰆼 ", "󰈹 ", " ", " ", " " }
awful.util.tagnames = tagnames

-- Global (not local): called externally via `awesome-client 'focus_terminal_tag()'`
-- (opencode's focus-tmux-pane plugin, nvim-dap's event_stopped listener),
-- whose separate execution context can't see this file's locals.
function focus_terminal_tag()
	local s = awful.screen.focused()
	local t = s.tags[2]
	if t then
		t:view_only()
	end
end

-- Per-tag wallpapers (see wallpaper.lua). Caches a pre-scaled surface per
-- tag so switches are near-instant after the first (background-warmed) visit.
local set_tag_wallpaper = require("./wallpaper").setup(#tagnames)

awful.layout.layouts = {
	-- awful.layout.suit.floating,
	awful.layout.suit.tile,
}

awful.util.taglist_buttons = mytable.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

awful.util.tasklist_buttons = mytable.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

beautiful.init(
	string.format("%s/.config/awesome/bar.lua", os.getenv("HOME"))
)

-- }}}

-- {{{ Menu

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

awful.util.mymainmenu = freedesktop.menu.build({
	before = {
		{ "Awesome", myawesomemenu, beautiful.awesome_icon },
		-- other triads can be put here
	},
	after = {
		{ "Open terminal", terminal },
		-- other triads can be put here
	},
})

-- Hide the menu when the mouse leaves it
--[[
awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function()
    if not awful.util.mymainmenu.active_child or
       (awful.util.mymainmenu.wibox ~= mouse.current_wibox and
       awful.util.mymainmenu.active_child.wibox ~= mouse.current_wibox) then
        awful.util.mymainmenu:hide()
    else
        awful.util.mymainmenu.active_child.wibox:connect_signal("mouse::leave",
        function()
            if awful.util.mymainmenu.wibox ~= mouse.current_wibox then
                awful.util.mymainmenu:hide()
            end
        end)
    end
end)
--]]

-- Set the Menubar terminal for applications that require it
--menubar.utils.terminal = terminal

-- }}}

-- {{{ Screen

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s)
	beautiful.at_screen_connect(s)
	-- property::selected only fires on switches; paint the initially-selected
	-- tag's wallpaper here since it's already selected by the time tags exist.
	set_tag_wallpaper(s.selected_tag)
end)

-- }}}

-- {{{ Key bindings
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

	-- By-direction client focus
	awful.key({ modkey }, "j", function()
		awful.client.focus.global_bydirection("down")
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus down", group = "client" }),
	awful.key({ modkey }, "k", function()
		awful.client.focus.global_bydirection("up")
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus up", group = "client" }),
	awful.key({ modkey }, "h", function()
		awful.client.focus.global_bydirection("left")
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus left", group = "client" }),
	awful.key({ modkey }, "l", function()
		awful.client.focus.global_bydirection("right")
		if client.focus then
			client.focus:raise()
		end
	end, { description = "focus right", group = "client" }),

	-- Menu
	--[[ awful.key({ modkey }, "w", function()
		awful.util.mymainmenu:show()
	end, { description = "show main menu", group = "awesome" }), ]]

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
		awful.screen.focus_relative(-1)
	end, { description = "toggle focus between screens", group = "screen" }),

	-- Show/hide wibox
	awful.key({ modkey }, "x", function()
		for s in screen do
			s.mywibox.visible = not s.mywibox.visible
			if s.mybottomwibox then
				s.mybottomwibox.visible = not s.mybottomwibox.visible
			end
		end
	end, { description = "toggle wibox", group = "awesome" }),

	-- Launching Programs
	awful.key({ modkey }, "Return", function()
		awful.spawn(terminal)
	end, { description = "open a terminal", group = "launcher" }),
	awful.key(
		{ modkey, "Control" },
		"r",
		awesome.restart,
		{ description = "reload awesome", group = "awesome" }
	),
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
		awful.spawn.with_shell(
			"maim -o -s | xclip -selection clipboard -t image/png && notify-send 'Screenshot' 'Copied to clipboard'"
		)
	end, { description = "screenshot region to clipboard", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "s", function()
		awful.spawn.with_shell("~/.config/awesome/scripts/recording.sh")
	end, { description = "toggle screen recording", group = "launcher" }),
	awful.key({ modkey }, "e", function()
		awful.spawn("pcmanfm")
	end, { description = "open a explorer", group = "launcher" }),
	awful.key({ modkey }, "p", function()
		awful.spawn.with_shell("copyq toggle")
	end, { description = "toggle clipboard manager", group = "launcher" }),
	-- Voice dictation — sway parity (needs `ydotool` + `ydotoold` on X11)
	awful.key({ modkey }, "d", function()
		awful.spawn.with_shell("hyprvoice toggle")
	end, { description = "toggle voice dictation", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "d", function()
		awful.spawn.with_shell("hyprvoice cancel")
	end, { description = "cancel voice dictation", group = "launcher" }),
	awful.key({ modkey, "Shift" }, "l", function()
		awful.spawn.with_shell("slock")
	end, { description = "lock screen", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "o", function()
		awful.spawn.with_shell("obsidian")
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

	-- Dropdown application
	--[[ awful.key({ modkey }, "z", function()
		awful.screen.focused().quake:toggle()
	end, { description = "dropdown application", group = "launcher" }),
]]
	-- Widgets popups
	-- awful.key({ altkey }, "c", function()
	-- 	if beautiful.cal then
	-- 		beautiful.cal.show(7)
	-- 	end
	-- end, { description = "show calendar", group = "widgets" }),
	-- awful.key({ altkey }, "h", function()
	-- 	if beautiful.fs then
	-- 		beautiful.fs.show(7)
	-- 	end
	-- end, { description = "show filesystem", group = "widgets" }),
	-- awful.key({ altkey }, "w", function()
	-- 	if beautiful.weather then
	-- 		beautiful.weather.show(7)
	-- 	end
	-- end, { description = "show weather", group = "widgets" }),

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

	-- Default
	--[[ Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
    --]]
	-- dmenu
	-- dmenu — colours/font mirror sway/scripts/launcher.sh (wmenu-run)
	awful.key({ modkey }, "r", function()
		awful.spawn.with_shell(
			"dmenu_run -i -fn 'NotoSans Nerd Font-10'"
				.. " -nb '#1d2021' -nf '#d4be98' -sb '#689d6a' -sf '#1d2021'"
		)
	end, { description = "show dmenu", group = "launcher" })
	--
	-- alternatively use rofi, a dmenu-like application with more features
	-- check https://github.com/DaveDavenport/rofi for more details
	--[[ rofi
    awful.key({ modkey }, "x", function ()
            os.execute(string.format("rofi -show %s -theme %s",
            'run', 'dmenu'))
        end,
        {description = "show rofi", group = "launcher"}),
    --]]
	-- Prompt
	--[[ awful.key({ modkey }, "r", function()
		awful.screen.focused().mypromptbox:run()
	end, { description = "run prompt", group = "launcher" }),

	awful.key({ modkey }, "x", function()
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end, { description = "lua execute prompt", group = "awesome" }) ]]
)

local clientkeys = mytable.join(
	-- Resize windows
	awful.key({ modkey }, "Up", function(c)
		if c.floating then
			c:relative_move(0, 0, 0, -50)
		else
			awful.client.incwfact(0.1)
		end
	end, { description = "Window Resize Vertical -", group = "client" }),
	awful.key({ modkey }, "Down", function(c)
		if c.floating then
			c:relative_move(0, 0, 0, 50)
		else
			awful.client.incwfact(-0.1)
		end
	end, { description = "Window Resize Vertical +", group = "client" }),
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

-- No borders when rearranging only 1 non-floating or maximized client
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

local clientbuttons = mytable.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(globalkeys)

-- }}}

-- {{{ Rules
local target_screen = screen_count > 1 and 2 or 1

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
			buttons = clientbuttons,
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

-- }}}

-- {{{ Signals

-- Signal function to execute when a new client appears.
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

-- }}}

-- AutoStart script
awful.spawn.with_shell("~/.config/awesome/autostart.sh")
