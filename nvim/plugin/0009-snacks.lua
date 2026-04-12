vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
	bigfile = { enabled = true, notify = false },
	image = { enabled = true },
	rename = { enabled = true },
	quickfile = { enabled = true },
	indent = {
		indent = { enabled = false },
		scope = { enabled = true, char = "┊", hl = "SnacksIndentScope" },
		animate = { enabled = false },
	},
	picker = {
		prompt = " ",
		on_change = function(picker, item)
			if item and item.file and picker.preview.title ~= item.file then
				vim.schedule(function()
					picker.preview.title = item.file
					picker:update_titles()
				end)
			end
		end,
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
							width = 0.6,
							border = "top",
							title_pos = "left",
						},
					},
				},
			},
		},
		layout = { preset = "ivy" },
		matcher = { frecency = true, cwd_bonus = true },
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
		formatters = {
			file = { filename_first = true, truncate = "left" },
			selected = { show_always = true, unselected = false },
		},
	},
})

local snacks = require("snacks").picker
local opts = { noremap = true, silent = true }

opts.desc = "[F]ind Project [F]iles"
vim.keymap.set("n", "<leader>ff", function()
	local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
	if git_dir ~= "" then
		snacks.git_files()
	else
		snacks.files()
	end
end, opts)

opts.desc = "[F]ind Snacks [B]uffers"
vim.keymap.set("n", "<leader>fb", function()
	snacks.buffers()
end, opts)

opts.desc = "[F]ind Snacks [B]uiltins"
vim.keymap.set("n", "<leader>fm", function()
	snacks.pickers()
end, opts)

opts.desc = "[L]ive [G]rep Project-wide"
vim.keymap.set("n", "<leader>lg", function()
	snacks.grep()
end, opts)

opts.desc = "Find [H]elp [T]ags"
vim.keymap.set("n", "<leader>ht", function()
	snacks.help({
		actions = {
			confirm = function(_, item)
				if item then
					vim.cmd("vsplit | help " .. item.tag)
				end
			end,
		},
	})
end, opts)

opts.desc = "Find [N]eovim [P]lugins"
vim.keymap.set("n", "<leader>np", function()
	snacks.files({
		cwd = vim.fs.joinpath(
			vim.fn.stdpath("data"),
			"site",
			"pack",
			"core",
			"opt"
		),
	})
end, opts)

opts.desc = "[F]ind [S]pecific [S]tring"
vim.keymap.set("n", "<leader>fs", function()
	local search_string = vim.fn.input("Grep string > ")
	if search_string ~= "" then
		snacks.grep({ search = search_string })
	end
end, opts)

opts.desc = "[/] Fuzzily search in current buffer"
vim.keymap.set("n", "<leader>/", function()
	snacks.lines({
		layout = { preset = "select" },
	})
end, opts)
