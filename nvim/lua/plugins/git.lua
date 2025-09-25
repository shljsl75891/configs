return {
	"tpope/vim-fugitive",
	cmd = { "G", "Git" },
	keys = {
		{
			"<leader>gvd",
			"<cmd>Gvdiffsplit<CR>",
			desc = "Open current file in [G]it split [D]iff view",
		},
		{ "<leader>gs", "<cmd>vertical G<CR>", desc = "Show [G]it [S]tatus" },
		{
			"<leader>gb",
			"<cmd>G blame<CR>",
			desc = "Show [G]it [B]lame for each line of current file",
		},
	},
	init = function()
		vim.g.fugitive_git_executable = "HUSKY=0 git"
	end,
}
