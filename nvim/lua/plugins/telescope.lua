return {
	"nvim-telescope/telescope.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-telescope/telescope-node-modules.nvim",
	},
	keys = {
		{
			"<leader>ff",
			function()
				vim.fn.system("git rev-parse --is-inside-work-tree")
				if vim.v.shell_error == 0 then
					require("telescope.builtin").git_files()
				else
					require("telescope.builtin").find_files()
				end
			end,
			desc = "[F]ind Project [F]iles",
		},
		{
			"<leader>cf",
			function()
				local buffer_dir = require("telescope.utils").buffer_dir()
				vim.fn.system(
					"git -C "
						.. vim.fn.shellescape(buffer_dir)
						.. " rev-parse --is-inside-work-tree"
				)
				if vim.v.shell_error == 0 then
					local git_root = vim.fn
						.system(
							"git -C "
								.. vim.fn.shellescape(buffer_dir)
								.. " rev-parse --show-toplevel"
						)
						:gsub("\n", "")
					require("telescope.builtin").git_files({ cwd = git_root })
				else
					require("telescope.builtin").find_files({
						cwd = buffer_dir,
					})
				end
			end,
			desc = "[F]ind [C]urrent Buffer Git [F]iles",
		},
		{
			"<leader>fb",
			function()
				require("telescope.builtin").buffers()
			end,
			desc = "[F]ind Telescope [B]uffers",
		},
		{
			"<leader>fn",
			function()
				require("telescope._extensions.node_modules_builtin").list()
			end,
			desc = "[F]ind [N]ode Modules",
		},
		{
			"<leader>fB",
			function()
				require("telescope.builtin").builtin()
			end,
			desc = "[F]ind Telescope [B]uiltins",
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
	config = function()
		local actions = require("telescope.actions")

		require("telescope").setup({
			defaults = {
				preview = {
					filesize_limit = 10,
					highlight_limit = 0.5,
					timeout = 150,
					treesitter = true,
					check_mime_type = true,
				},
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--trim",
				},
				file_ignore_patterns = {
					"node_modules",
					"%.git/",
					"dist",
					"%.angular",
					"%.lock",
				},
				path_display = { "truncate" },
				hl_result_eol = true,
				wrap_results = false,
				dynamic_preview_title = false,
				sorting_strategy = "ascending",
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						width = 0.85,
						preview_width = 0.45,
						prompt_position = "top",
					},
					vertical = { width = 0.6, preview_width = 0.5 },
				},
				mappings = {
					i = {
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-l>"] = actions.smart_send_to_loclist + actions.open_loclist,
						["<C-j>"] = actions.cycle_history_next,
						["<C-k>"] = actions.cycle_history_prev,
					},
				},
			},
			pickers = {
				lsp_definitions = { fname_width = 100 },
				lsp_references = { fname_width = 100 },
				buffers = {
					sort_mru = true,
					ignore_current_buffer = true,
					mappings = {
						i = { ["<C-d>"] = actions.delete_buffer },
					},
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				["ui-select"] = {
					require("telescope.themes").get_cursor({
						previewer = false,
						layout_config = { height = 15 },
					}),
				},
			},
		})

		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
		require("telescope").load_extension("node_modules")
	end,
}
