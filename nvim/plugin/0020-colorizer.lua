vim.pack.add({ "https://github.com/catgoose/nvim-colorizer.lua" })

require("colorizer").setup({
	lazy_load = true,
	options = {
		parsers = {
			names = { enable = false },
			hex = {
				rgb = false,
				rgba = false,
				rrggbb = true,
				rrggbbaa = false,
				aarrggbb = false,
			},
		},
	},
})
