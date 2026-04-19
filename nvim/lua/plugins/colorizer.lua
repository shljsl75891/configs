return {
	{
		"catgoose/nvim-colorizer.lua",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
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
		},
	},
}
