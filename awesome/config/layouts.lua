local awful = require("awful")

awful.layout.layouts = {
	awful.layout.suit.tile,
}

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
