return {
	"f-person/git-blame.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("gitblame").setup({
			enabled = false,
		})
		Remap("n", "<leader>gb", vim.cmd.GitBlameToggle)
	end,
}
