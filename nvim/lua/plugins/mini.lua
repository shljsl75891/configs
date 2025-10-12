return {
	{
		"nvim-mini/mini.cursorword",
		event = { "BufReadPost", "BufNewFile" },
		version = false,
		opts = { delay = 800 },
	},
	{
		"nvim-mini/mini.notify",
		version = false,
		event = "VeryLazy",
		opts = {
			window = {
				config = {
					anchor = "SE",
					border = "none",
					col = vim.o.columns,
					row = vim.o.lines - vim.o.cmdheight - 2,
				},
				winblend = 0,
			},
		},
	},
}
