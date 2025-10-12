return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		filetypes = { ["*"] = true },
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 250,
			trigger_on_accept = true,
			keymap = {
				accept = "<C-y>",
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
		},
		panel = { enabled = false },
	},
}
