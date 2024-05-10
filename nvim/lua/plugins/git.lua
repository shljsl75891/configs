return {
	"tpope/vim-fugitive",
	cmd = { "G", "Git" },
	keys = {
		"<leader>gd",
		"<leader>gs",
		"<leader>gb",
	},
	config = function()
		vim.keymap.set("n", "<leader>gd", function()
			vim.cmd("Gvdiffsplit")
		end, { desc = "Open current file in [G]it split [D]iff view" })
		vim.keymap.set("n", "<leader>gs", function()
			vim.cmd("vertical G")
		end, { desc = "Show [G]it [S]tatus" })
		vim.keymap.set("n", "<leader>gb", function()
			vim.cmd("G blame")
		end, { desc = "Show [G]it [B]lame for each line of current file" })
	end,
}
