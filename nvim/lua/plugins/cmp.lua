return {
	"Saghen/blink.cmp",
	version = "*",
	opts = {
		keymap = {
			preset = "default",
			["<CR>"] = { "select_and_accept", "fallback" },
		},
		appearance = { nerd_font_variant = "normal" },
		signature = {
			enabled = true,
			window = { border = "solid", show_documentation = true },
		},
		cmdline = { enabled = false },
		completion = {
			menu = {
				border = "none",
				draw = { columns = { { "label", "label_description", gap = 1 } } },
			},
			ghost_text = { enabled = false },
			accept = { auto_brackets = { enabled = false } },
			documentation = {
				window = { border = "solid" },
				auto_show = true,
				auto_show_delay_ms = 350,
			},
			trigger = {
				show_on_keyword = true,
				show_on_insert_on_trigger_character = false,
			},
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "dadbod" },
			providers = {
				dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
			},
		},
	},
	opts_extend = { "sources.default" },
}
