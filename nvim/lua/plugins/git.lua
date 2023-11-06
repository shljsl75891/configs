return {
	"tpope/vim-fugitive",
	config = function()
		Remap("n", "<leader>gs", function()
			vim.cmd("vertical G")
		end)
	end,
}
