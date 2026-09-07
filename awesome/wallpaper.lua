-- wallpaper.lua — per-tag wallpapers.
--
-- Each tag gets a random image from a folder, picked once at startup and
-- fixed for the whole session (no hourly rotation, no external tool needed --
-- gears.wallpaper repaints the root directly). Reshuffles on the next
-- awesome restart / relogin.

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local cairo = require("lgi").cairo

local M = {}

local wallpaper_dir = os.getenv("HOME") .. "/gitprojects/wallpapers"

-- gears.wallpaper.maximized() decodes+scales+paints from the source JPEG on
-- every call, uncached (surface.load_uncached + surf:finish()). Measured
-- 380-440ms for the 4K images in this folder -- enough to stall awesome's
-- main loop on every tag switch. Instead we decode once per tag into a
-- root.size()-sized cairo surface, cache it, and hand that straight to
-- gears.wallpaper.set() (no decode/scale) on every switch after the first.
local function build_surface(path)
	local src = gears.surface.load_uncached(path)
	local w, h = gears.surface.get_size(src)
	local rw, rh = root.size()

	local target = cairo.ImageSurface(cairo.Format.RGB24, rw, rh)
	local cr = cairo.Context(target)
	local scale = math.max(rw / w, rh / h)
	cr:scale(scale, scale)
	cr:translate((rw / scale - w) / 2, (rh / scale - h) / 2)
	cr:set_source_surface(src, 0, 0)
	cr.operator = cairo.Operator.SOURCE
	cr:paint()
	src:finish()

	return target
end

-- tag_count: number of tags to assign images to (e.g. #tagnames)
-- Returns the set_tag_wallpaper(t) function, so the caller can also invoke it
-- directly for the initially-selected tag (property::selected doesn't fire
-- for a tag that's already selected when it's created).
function M.setup(tag_count)
	local tag_wallpapers = {}
	local tag_surfaces = {}

	local function set_tag_wallpaper(t)
		if not t or not t.selected then
			return
		end
		local idx = t.index
		local path = tag_wallpapers[idx]
		if not path then
			return
		end
		if not tag_surfaces[idx] then
			tag_surfaces[idx] = build_surface(path)
		end
		gears.wallpaper.set(tag_surfaces[idx])
	end

	-- property::selected fires on both select and deselect; the guard above
	-- (t.selected) stops the outgoing tag from repainting too. Registered
	-- synchronously so no tag-switch during the async scan below is missed
	-- (tag_wallpapers is just empty until the scan finishes).
	tag.connect_signal("property::selected", set_tag_wallpaper)

	-- fdfind (Ubuntu package name for fd) over find: faster directory scan.
	-- Argv form (no shell) avoids interpolating wallpaper_dir into a shell
	-- string, and easy_async keeps this off awesome's main loop at startup.
	awful.spawn.easy_async(
		{ "fdfind", "--max-depth", "1", "--extension", "jpg", "--type", "f", ".", wallpaper_dir },
		function(stdout, stderr, _, exit_code)
			if exit_code ~= 0 then
				naughty.notify({
					preset = naughty.config.presets.critical,
					title = "wallpaper.lua",
					text = "fdfind failed (is fd-find installed?): " .. (stderr ~= "" and stderr or "unknown error"),
				})
				return
			end

			local files = {}
			for line in stdout:gmatch("[^\r\n]+") do
				table.insert(files, line)
			end

			if #files == 0 then
				naughty.notify({
					preset = naughty.config.presets.low,
					title = "wallpaper.lua",
					text = "No .jpg files found in " .. wallpaper_dir,
				})
				return
			end

			math.randomseed(os.time())
			for i = 1, tag_count do
				tag_wallpapers[i] = files[math.random(#files)]
			end

			-- Paint whatever tag is currently selected on each screen now
			-- that images are available (the initial-tag call from rc.lua
			-- ran before this callback fired and was a no-op).
			for s in screen do
				set_tag_wallpaper(s.selected_tag)
			end

			-- Warm the rest of the tags in the background, one per tick,
			-- instead of blocking startup for ~380ms x tag_count. Any tag
			-- switched to before its turn is built on-demand above anyway.
			local warm_idx = 0
			local warm_timer = gears.timer({ timeout = 1.5, autostart = true })
			warm_timer:connect_signal("timeout", function()
				warm_idx = warm_idx + 1
				if warm_idx > tag_count then
					warm_timer:stop()
					return
				end
				if tag_wallpapers[warm_idx] and not tag_surfaces[warm_idx] then
					tag_surfaces[warm_idx] = build_surface(tag_wallpapers[warm_idx])
				end
			end)
		end
	)

	return set_tag_wallpaper
end

return M
