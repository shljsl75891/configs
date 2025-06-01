return {
	"stevearc/oil.nvim",
	event = "VimEnter",
	keys = {
		{ "-", "<cmd>Oil<CR>", desc = "open Oil file explorer" },
	},
	opts = {
		skip_confirm_for_simple_edits = true,
		float = { border = "solid" },
		confirmation = { border = "solid" },
		progress = { border = "solid" },
		keymaps_help = { border = "solid" },
		ssh = { border = "solid" },
		view_options = { show_hidden = true },
		lsp_file_methods = {
			enabled = true,
			timeout_ms = 1000,
			autosave_changes = true,
		},
	},
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
}
