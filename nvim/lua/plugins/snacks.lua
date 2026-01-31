return {
	"folke/snacks.nvim",
	event = "VimEnter",
	opts = {
		bigfile = { enabled = true },
		image = { enabled = true },
		rename = { enabled = true },
		picker = {
			prompt = " ",
			layouts = {
				select = {
					layout = {
						backdrop = false,
						width = 0.5,
						min_width = 80,
						max_width = 100,
						height = 0.4,
						min_height = 2,
						box = "vertical",
						border = "bottom",
						title = "",
						{ win = "input", height = 1, border = vim.o.winborder },
						{ win = "list", border = "none" },
						{
							win = "preview",
							title = "{preview}",
							height = 0.4,
							border = "none",
						},
					},
				},
				ivy = {
					layout = {
						box = "vertical",
						backdrop = false,
						row = -1,
						width = 0,
						height = 0.45,
						border = "bottom",
						title = "{live} {flags}",
						{ win = "input", height = 1, border = vim.o.winborder },
						{
							box = "horizontal",
							{ win = "list", border = "none" },
							{
								win = "preview",
								title = "{preview}",
								width = 0.5,
								border = "none",
							},
						},
					},
				},
			},
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
			desc = "[F]ind Snacks [B]uffers",
		},
		{
			"<leader>fm",
			function()
				require("snacks").picker.pickers()
			end,
			desc = "[F]ind Snacks [B]uiltins",
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
				require("snacks").picker.lines({
					layout = { preset = "select" },
				})
			end,
			desc = "[/] Fuzzily search in current buffer",
		},
	},
}
