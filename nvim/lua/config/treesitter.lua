require("nvim-treesitter.install").prefer_git = false

require("treesitter-context").setup({
	enable = true,
	mode = "cursor",
	line_numbers = true,
	multiline_threshold = 1,
})

local configs = require("nvim-treesitter.configs")
configs.setup({
	ensure_installed = {
		"c",
		"lua",
		"vim",
		"vimdoc",
		"markdown",
		"markdown_inline",
		"javascript",
		"typescript",
		"tsx",
		"yaml",
		"json",
		"tmux",
		"gitcommit",
		"angular",
		"diff",
		"html",
		"css",
		"scss",
		"toml",
		"xml",
		"jsonc",
		"sql",
		"bash",
	},
	auto_install = true,
	sync_install = false,
	highlight = { enable = true },
	indent = { enable = true },
})
