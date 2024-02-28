return {
	"tpope/vim-fugitive",
	config = function()
		Remap("n", "<leader>gd", function()
			vim.cmd("Gvdiffsplit")
		end)
		Remap("n", "<leader>gs", function()
			vim.cmd("vertical G")
		end)
	end,
}
