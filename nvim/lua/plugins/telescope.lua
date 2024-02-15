return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.5",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		-- Keymaps
		local builtin = require("telescope.builtin")
		Remap("n", "<leader>ff", builtin.find_files, {})
		Remap("n", "<leader>fb", builtin.buffers, {})
		Remap("n", "<leader>fo", builtin.oldfiles, {})
		Remap("n", "<leader>lg", builtin.live_grep, {})
		Remap("n", "<leader>cp", builtin.registers, {})
		Remap("n", "<leader>gb", builtin.git_branches, {})
		Remap("n", "<leader>ht", builtin.help_tags, {})

		require("telescope").setup({
			defaults = {
				mappings = {
					i = {},
				},
			},
			pickers = {
				lsp_definitions = { fname_width = 100 },
				lsp_references = { fname_width = 100 },
			},
			extensions = {},
		})
	end,
}
