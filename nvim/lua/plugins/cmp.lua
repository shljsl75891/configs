return {
	"Saghen/blink.cmp",
	version = "*",
	opts = {
		keymap = {
			preset = "default",
			["<CR>"] = { "select_and_accept", "fallback" },
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "normal",
		},
		signature = { enabled = true },
		completion = {
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 350,
			},
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "dadbod" },
			providers = {
				dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
			},
			-- Disable cmdline autocompletion
			cmdline = {},
		},
	},
	opts_extend = { "sources.default" },
}
