return {
	"stevearc/oil.nvim",
	event = { "VimEnter */*,.*" },
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = { "<leader>b" },
	config = function()
		require("oil").setup({
			lsp_file_methods = {
				timeout_ms = 2000,
				autosave_changes = true,
			},
			preview = {
				border = "solid",
			},
			view_options = {
				show_hidden = true,
			},
			keymaps_help = {
				border = "solid",
			},
			default_file_explorer = true,
		})

		-- Open Explorer
		vim.keymap.set("n", "-", vim.cmd.Oil)
	end,
}
