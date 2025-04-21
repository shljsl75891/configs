local actions = require("telescope.actions")

-- Global config
require("telescope").setup({
	defaults = {
		-- could be `horizontal` or `vertical
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = { width = 0.85, preview_width = 0.45 },
			vertical = { width = 0.6, preview_width = 0.5 },
		},
		mappings = {
			i = {
				["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
				["<C-j>"] = actions.cycle_history_next,
				["<C-k>"] = actions.cycle_history_prev,
			},
		},
	},
	pickers = {
		find_files = {
			find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
		},
		lsp_definitions = { fname_width = 100 },
		lsp_references = { fname_width = 100 },
	},
	extensions = {},
})

-- Load fzf-native extensions for capabilites like exact, suffix, prefix matching
require("telescope").load_extension("fzf")
