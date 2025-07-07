return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = { "nvim-treesitter/nvim-treesitter-context" },
	config = function()
		require("nvim-treesitter.install").prefer_git = false

		require("treesitter-context").setup({
			enable = true,
			mode = "cursor",
			line_numbers = true,
			multiline_threshold = 1,
		})

		require("nvim-treesitter.configs").setup({
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
				"git_config",
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
	end,
}
