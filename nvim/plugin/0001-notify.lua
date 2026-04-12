vim.pack.add({ "https://github.com/nvim-mini/mini.notify" })

require("mini.notify").setup({
	window = {
		config = {
			anchor = "SE",
			border = "none",
			col = vim.o.columns,
			row = vim.o.lines - vim.o.cmdheight - 2,
		},
		winblend = 0,
	},
})
