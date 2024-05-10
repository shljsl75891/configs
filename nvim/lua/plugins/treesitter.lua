return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = { "nvim-treesitter/nvim-treesitter-context" },
	config = function()
		require("nvim-treesitter.install").prefer_git = false

		require("treesitter-context").setup({
			enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
			mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
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
				"json",
				"html",
				"css",
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
