local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")

local ICON_OFF, ICON_ON, ICON_CONNECTED = "󰂲 ", " ", "󰂴 "
local SCAN_SECONDS = 10

local function sh(cmd, callback)
	awful.spawn.easy_async_with_shell(cmd, callback or function() end)
end

local function notify(text)
	naughty.notify({ title = "Bluetooth", text = gears.string.xml_escape(text) })
end

--- Parse `bluetoothctl devices` output into a list of { mac, name }.
local function parse_devices(output)
	local devices = {}
	for mac, name in output:gmatch("Device (%S+) ([^\n]*)") do
		devices[#devices + 1] = { mac = mac, name = name }
	end
	return devices
end

local function connected_set(output)
	local set = {}
	for _, device in ipairs(parse_devices(output)) do
		set[device.mac] = true
	end
	return set
end

local widget, timer = awful.widget.watch(
	{
		"sh",
		"-c",
		[[bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off; bluetoothctl devices Connected]],
	},
	15,
	function(self, stdout)
		local powered = stdout:match("^on") ~= nil
		local connected = parse_devices(stdout)
		local text = ICON_OFF .. " BT"
		if #connected > 0 then
			text = ICON_CONNECTED .. " " .. connected[1].name
		elseif powered then
			text = ICON_ON .. " BT"
		end
		self:set_font(beautiful.font)
		self:set_text(text)
	end
)

local function refresh()
	timer:emit_signal("timeout")
end

local function toggle_power()
	sh(
		[[if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else rfkill unblock bluetooth; bluetoothctl power on; fi]],
		refresh
	)
end

local function run_and_report(cmd, success)
	sh(cmd, function(out, err, _, code)
		notify(code == 0 and success or (out .. err):gsub("%s+$", ""))
		refresh()
	end)
end

local function pair(device)
	notify("Pairing " .. device.name .. "…")
	run_and_report(
		string.format(
			"bluetoothctl pair %s && bluetoothctl trust %s && bluetoothctl connect %s",
			device.mac,
			device.mac,
			device.mac
		),
		"Connected " .. device.name
	)
end

local menu

local function show_menu(items)
	if menu then
		menu:hide()
	end
	menu = awful.menu({ items = items })
	menu:show()
end

local function scan()
	notify("Scanning for " .. SCAN_SECONDS .. "s…")
	sh(
		string.format(
			"bluetoothctl --timeout %d scan on >/dev/null; bluetoothctl devices; echo ---; bluetoothctl devices Paired",
			SCAN_SECONDS
		),
		function(out)
			local all, paired = out:match("^(.-)%-%-%-\n(.*)$")
			local known = connected_set(paired or "")
			local items = {}
			for _, device in ipairs(parse_devices(all or "")) do
				if not known[device.mac] then
					items[#items + 1] = {
						device.name,
						function()
							pair(device)
						end,
					}
				end
			end
			if #items == 0 then
				items[1] = { "No new devices found", function() end }
			end
			show_menu(items)
		end
	)
end

local function open_menu()
	sh(
		"bluetoothctl devices Paired; echo ---; bluetoothctl devices Connected",
		function(out)
			local paired, connected = out:match("^(.-)%-%-%-\n(.*)$")
			local on = connected_set(connected or "")
			local items = {}
			for _, device in ipairs(parse_devices(paired or "")) do
				local verb = on[device.mac] and "disconnect" or "connect"
				items[#items + 1] = {
					(on[device.mac] and "✓ " or "  ") .. device.name,
					function()
						run_and_report(
							string.format("bluetoothctl %s %s", verb, device.mac),
							verb .. " " .. device.name .. ": ok"
						)
					end,
				}
			end
			items[#items + 1] = { "Scan for new devices…", scan }
			show_menu(items)
		end
	)
end

local buttons = gears.table.join(
	awful.button({}, 3, open_menu),
	awful.button({}, 2, toggle_power)
)

return { widget = widget, buttons = buttons }
