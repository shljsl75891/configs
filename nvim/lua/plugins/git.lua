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
		end)
		vim.keymap.set("n", "<leader>gs", function()
			vim.cmd("vertical G")
		end)
		vim.keymap.set("n", "<leader>gb", function()
			vim.cmd("G blame")
		end)
	end,
}
