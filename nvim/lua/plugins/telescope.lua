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
			desc = "[F]ind Telescope [B]uffers",
		},
		{
			"<leader>fm",
			function()
				require("telescope.builtin").builtin()
			end,
			desc = "[F]ind Telescope [M]ore Builtins",
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
			"<leader>fif",
			function()
				require("telescope.builtin").find_files({ no_ignore = true })
			end,
			desc = "[F]ind [I]gnored [F]iles",
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

		{
			"<leader>/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find(
					require("telescope.themes").get_dropdown({ previewer = false })
				)
			end,
			{ desc = "[/] Fuzzily search in current buffer" },
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		local actions = require("telescope.actions")

		-- Global config
		require("telescope").setup({
			defaults = {
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
					require("telescope.themes").get_cursor({ previwer = false }),
				},
			},
		})

		-- Load fzf-native extensions for capabilites like exact, suffix, prefix matching
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
	end,
}
