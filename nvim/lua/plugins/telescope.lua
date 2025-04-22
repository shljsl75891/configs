return {
	"nvim-telescope/telescope.nvim",
	cmd = { "Telescope" },
	keys = {
		{
			"<leader>ff",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "[F]ind Project [F]iles",
		},
		{
			"<leader>fb",
			function()
				require("telescope.builtin").buffers()
			end,
			desc = "[F]ind [B]uffers",
		},
		{
			"<leader>lg",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "[L]ive [G]rep Project-wide",
		},
		{
			"<leader>ht",
			function()
				require("telescope.builtin").help_tags()
			end,
			desc = "Find [H]elp [T]ags",
		},
		{
			"<leader>np",
			function()
				require("telescope.builtin").find_files({ cwd = "~/.local/share/nvim" })
			end,
			desc = "Find [N]eovim [P]lugins",
		},
		{
			"<leader>fsf",
			function()
				local search_file = vim.fn.input("Name of File > ")
				if search_file ~= "" then
					require("telescope.builtin").find_files({ search_file = search_file })
				end
			end,
			desc = "[F]ind [S]pecific [F]ile using its name",
		},
		{
			"<leader>fss",
			function()
				local search_string = vim.fn.input("Grep string > ")
				if search_string ~= "" then
					require("telescope.builtin").grep_string({ search = search_string })
				end
			end,
			desc = "[F]ind [S]pecific [S]tring",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		require("configs.telescope")
	end,
}
