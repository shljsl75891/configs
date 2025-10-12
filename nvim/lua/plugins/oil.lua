return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-mini/mini.icons" },
	opts = {
		default_file_explorer = true,
		lsp_file_methods = {
			enabled = true,
			timeout_ms = 15000, -- 15 second timeout
			autosave_changes = true,
		},
		use_default_keymaps = true,
		view_options = { show_hidden = true },
		float = { padding = 0, border = vim.o.winborder },
		confirmation = { border = vim.o.winborder },
		progress = { border = vim.o.winborder },
		keymaps_help = { border = vim.o.winborder },
		ssh = { border = vim.o.winborder },
	},
}
