return {
	"nvim-telescope/telescope.nvim",
	cmd = { "Telescope" },
	keys = {
		{
			"<leader>ff",
			require("telescope.builtin").find_files,
			desc = "[F]ind Project [F]iles",
		},
		{
			"<leader>fb",
			require("telescope.builtin").builtin,
			desc = "[F]ind Telescope [B]uiltins",
		},
		{
			"<leader>lg",
			require("telescope.builtin").live_grep,
			desc = "[L]ive [G]rep Project-wide",
		},
		{
			"<leader>ht",
			require("telescope.builtin").help_tags,
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
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
		},
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		local actions = require("telescope.actions")

		-- Global config
		require("telescope").setup({
			defaults = {
				-- could be `horizontal` or `vertical
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = { width = 0.85, preview_width = 0.45 },
					vertical = { width = 0.6, preview_width = 0.5 },
				},
				mappings = {
					i = {
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-j>"] = actions.cycle_history_next,
						["<C-k>"] = actions.cycle_history_prev,
					},
				},
			},
			pickers = {
				find_files = {
					find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
				},
				lsp_definitions = { fname_width = 100 },
				lsp_references = { fname_width = 100 },
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({
						previwer = false,
						winblend = 0,
					}),
				},
			},
		})

		-- Load fzf-native extensions for capabilites like exact, suffix, prefix matching
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
	end,
}
