-- Awesome WM configuration; modules live in config/ and ui/.

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local awful = require("awful")
local beautiful = require("beautiful")
require("awful.autofocus")
require("awful.hotkeys_popup.keys")

require("config.errors")
local vars = require("config.vars")
require("config.layouts")

beautiful.init(
	string.format("%s/.config/awesome/ui/bar.lua", os.getenv("HOME"))
)

-- Per-tag wallpapers (see ui/wallpaper.lua). Caches a pre-scaled surface per
-- tag so switches are near-instant after the first (background-warmed) visit.
local set_tag_wallpaper = require("ui.wallpaper").setup(#vars.tagnames)

require("config.menu")

awful.screen.connect_for_each_screen(function(s)
	beautiful.at_screen_connect(s)
	-- property::selected only fires on switches; paint the initially-selected
	-- tag's wallpaper here since it's already selected by the time tags exist.
	set_tag_wallpaper(s.selected_tag)
end)

require("config.rules")
require("config.signals")

awful.spawn.with_shell("~/.config/awesome/autostart.sh")
