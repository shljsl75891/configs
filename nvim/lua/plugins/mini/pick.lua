return {
	"nvim-mini/mini.pick",
	version = false,
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "nvim-mini/mini.extra", version = false },
	},
	opts = {
		mappings = {
			delete_left = "",
			scroll_down = "<C-d>",
			scroll_up = "<C-u>",
			choose_in_vsplit = "<C-r>",
			paste = "<C-v>",
			scroll_left = "<C-Left>",
			scroll_right = "<C-Right>",
			send_to_qflist = {
				char = "<C-q>",
				func = function()
					local matches = require("mini.pick").get_picker_matches()
					local items = (#matches.marked > 0) and matches.marked or matches.all
					require("mini.pick").default_choose_marked(
						items,
						{ list_type = "quickfix" }
					)
					return true
				end,
			},
			send_to_loclist = {
				char = "<C-l>",
				func = function()
					local matches = require("mini.pick").get_picker_matches()
					local items = (#matches.marked > 0) and matches.marked or matches.all
					require("mini.pick").default_choose_marked(
						items,
						{ list_type = "location" }
					)
					return true
				end,
			},
		},
		options = {
			content_from_bottom = false,
			use_cache = true,
		},
		window = {
			config = {
				height = 25,
				width = 150,
				border = vim.o.winborder,
			},
			prompt_caret = "█",
			prompt_prefix = "",
		},
	},
	keys = {
		{
			"<leader>ff",
			function()
				vim.fn.system("git rev-parse --is-inside-work-tree")
				require("mini.pick").builtin.files({
					tool = vim.v.shell_error == 0 and "git",
				})
			end,
			desc = "Mini Pick [F]ind [F]iles",
		},
		{
			"<leader>if",
			function()
				require("mini.extra").pickers.git_files({ scope = "ignored" })
			end,
			desc = "Mini Pick find [I]gnored [F]iles",
		},
		{
			"<leader>np",
			function()
				require("mini.pick").builtin.files({}, {
					source = {
						cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
					},
				})
			end,
			desc = "Mini Pick [N]eovim [P]lugins",
		},
		{
			"<leader>ht",
			function()
				require("mini.pick").builtin.help({
					default_split = "vertical",
				})
			end,
			desc = "Mini Pick [H]elp [T]ags",
		},
		{
			"<leader>lg",
			function()
				require("mini.pick").builtin.grep_live()
			end,
			desc = "Mini Pick [L]ive [G]rep",
		},
		{
			"<leader>ex",
			function()
				local subdirectory = vim.fn.input("Relative Path >: /")
				local cwd = vim.fs.joinpath(vim.fn.getcwd(), subdirectory)
				require("mini.extra").pickers.explorer({ cwd = cwd })
			end,
			desc = "Mini Pick [E][X]plorer",
		},
		{
			"<leader>fd",
			function()
				require("mini.extra").pickers.diagnostic({ scope = "current" })
			end,
			desc = "Mini Pick [F]ind current buffer [D]iagnostics",
		},
		{
			"<leader>cp",
			function()
				require("mini.extra").pickers.registers()
			end,
			desc = "Mini Pick [C]lipboard [P]aste from registers",
		},
		{
			"<leader>/",
			function()
				require("mini.extra").pickers.buf_lines({
					scope = "current",
					preserve_order = true,
				})
			end,
			desc = "Mini Pick current buffer fuzzy find",
		},
		{
			"<leader>sg",
			function()
				require("mini.extra").pickers.spellsuggest()
			end,
			desc = "Mini Pick [S]pell [G]uess",
		},
		{
			"<leader>fs",
			function()
				local pattern = vim.fn.input("Grep String > ")
				if pattern ~= "" then
					require("mini.pick").builtin.cli({
						command = {
							"rg",
							"--fixed-strings",
							"--smart-case",
							"--column",
							"--line-number",
							"--no-heading",
							"--field-match-separator",
							"\\x00",
							"--color=never",
							"--",
							pattern,
						},
					}, {
						source = {
							show = function(buf_id, items, query)
								require("mini.pick").default_show(
									buf_id,
									items,
									query,
									{ show_icons = true }
								)
							end,
						},
					})
				end
			end,
			desc = "Mini Pick [F]ind [S]tring (literal)",
		},
	},
}
