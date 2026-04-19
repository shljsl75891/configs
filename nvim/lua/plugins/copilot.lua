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
			should_attach = function(_, bufname)
				return not string.match(bufname, "env")
			end,
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
	},
}
