return {
	"folke/snacks.nvim",
	event = "VimEnter",
	opts = {
		bigfile = { enabled = true },
		image = { enabled = true },
		rename = { enabled = true },
		picker = {
			layout = { preset = "ivy" },
			matcher = { frecency = true, cwd_bonus = true, sort_empty = true },
			win = {
				input = {
					keys = {
						["<ESC>"] = { "close", mode = { "i", "n" } },
						["<C-q>"] = { "qflist", mode = { "i", "n" } },
						["<C-x>"] = { "bufdelete", mode = { "i", "n" } },
						["<C-l>"] = { "loclist", mode = { "i", "n" } },
						["<C-j>"] = { "history_forward", mode = { "i", "n" } },
						["<C-k>"] = { "history_back", mode = { "i", "n" } },
						["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
						["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
					},
				},
			},
			formatters = { file = { filename_first = true, truncate = "left" } },
		},
	},
	keys = {
		{
			"<leader>ff",
			function()
				vim.fn.system("git rev-parse --is-inside-work-tree")
				if vim.v.shell_error == 0 then
					require("snacks").picker.git_files()
				else
					require("snacks").picker.files()
				end
			end,
			desc = "[F]ind Project [F]iles",
		},
		{
			"<leader>fb",
			function()
				require("snacks").picker.buffers()
			end,
			desc = "[F]ind Telescope [B]uffers",
		},
		{
			"<leader>fm",
			function()
				require("snacks").picker.pickers()
			end,
			desc = "[F]ind Telescope [B]uiltins",
		},
		{
			"<leader>lg",
			function()
				require("snacks").picker.grep()
			end,
			desc = "[L]ive [G]rep Project-wide",
		},
		{
			"<leader>ht",
			function()
				require("snacks").picker.help({
					actions = {
						confirm = function(_, item)
							if item then
								vim.cmd("vsplit | help " .. item.tag)
							end
						end,
					},
				})
			end,
			desc = "Find [H]elp [T]ags",
		},
		{
			"<leader>np",
			function()
				require("snacks").picker.files({
					cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
				})
			end,
			desc = "Find [N]eovim [P]lugins",
		},
		{
			"<leader>fs",
			function()
				local search_string = vim.fn.input("Grep string > ")
				if search_string ~= "" then
					require("snacks").picker.grep_word({ search = search_string })
				end
			end,
			desc = "[F]ind [S]pecific [S]tring",
		},
		{
			"<leader>/",
			function()
				require("snacks").picker.lines({ layout = { preset = "select" } })
			end,
			desc = "[/] Fuzzily search in current buffer",
		},
	},
}
