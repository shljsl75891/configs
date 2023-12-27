return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.3",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		-- Keymaps
		local builtin = require("telescope.builtin")
		Remap("n", "<leader>ff", builtin.find_files, {})
		Remap("n", "<leader>fb", builtin.buffers, {})
		Remap("n", "<leader>fo", builtin.oldfiles, {})
		Remap("n", "<leader>lg", builtin.live_grep, {})
		Remap("n", "<leader>fr", builtin.registers, {})
		Remap("n", "<leader>gb", builtin.git_branches, {})
	end,
}
