return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.install").prefer_git = false

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
