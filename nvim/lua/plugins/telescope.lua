return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.5",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local actions = require("telescope.actions")
		local builtin = require("telescope.builtin")
		-- Keymaps
		Remap("n", "<leader>ff", builtin.find_files, {})
		Remap("n", "<leader>fb", builtin.buffers, {})
		Remap("n", "<leader>lg", builtin.live_grep, {})
		Remap("n", "<leader>cp", builtin.registers, {})
		Remap("n", "<leader>ht", builtin.help_tags, {})
		Remap("n", "<leader>fw", builtin.grep_string)

		require("telescope").setup({
			defaults = {
				-- could be `horizontal` or `vertical
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						width = 0.85,
						preview_width = 0.45,
					},
					vertical = {
						width = 0.6,
						preview_width = 0.5,
					},
				},
				mappings = {
					n = {
						["<C-w>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
					i = {
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
	end,
}
