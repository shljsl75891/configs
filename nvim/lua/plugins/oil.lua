return {
	"stevearc/oil.nvim",
	opts = {
		lsp_file_methods = {
			-- Time to wait for LSP file operations to complete before skipping
			timeout_ms = 1000,
			-- Set to true to autosave buffers that are updated with LSP willRenameFiles
			-- Set to "unmodified" to only save unmodified buffers
			autosave_changes = true,
		},
		view_options = {
			-- Show files and directories that start with "."
			show_hidden = true,
		},
		-- Configuration for the floating window in oil.open_float
		float = {
			border = "solid",
		},
		-- Configuration for the actions floating preview window
		preview = {
			border = "solid",
		},
		-- Configuration for the floating progress window
		progress = {
			border = "solid",
		},
		-- Configuration for the floating SSH window
		ssh = {
			border = "solid",
		},
		-- Configuration for the floating keymaps help window
		keymaps_help = {
			border = "solid",
		},
	},
}
