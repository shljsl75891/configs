return {
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		opts = {
			filetypes = {
				["*"] = true,
				help = false,
				["snacks_picker_input"] = false,
				env = false,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = true,
				debounce = 75,
				trigger_on_accept = true,
				keymap = {
					accept = "<C-y>",
					accept_word = "<M-w>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			panel = { enabled = false },
		},
	},
}
