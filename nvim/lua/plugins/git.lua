return {
	"tpope/vim-fugitive",
	lazy = false,
	cmd = { "G", "Git" },
	dependencies = "tpope/vim-rhubarb",
	keys = {
		{ "<leader>gs", "<cmd>vertical G<CR>", desc = "Show [G]it [S]tatus" },
		{
			mode = { "n", "v" },
			"gh",
			":diffget //2<CR>",
			desc = "[G]et left hunk",
		},
		{
			mode = { "n", "v" },
			"gl",
			":diffget //3<CR>",
			desc = "[G]et right hunk",
		},
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
