return {
	modkey = "Mod4",
	altkey = "Mod1",
	terminal = "ghostty",
	editor = os.getenv("EDITOR") or "nvim",
	browser = "brave-origin",
	-- Tag icons mirror waybar sway/workspaces format-icons (waybar/config.jsonc)
	tagnames = { " ", " ", " ", "󰙨 ", "󰆼 ", "󰈹 ", " ", " ", " " },
}
