return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = {
		lazy_load = true,
		user_default_options = {
			names = false,
			RGB = true,
			RGBA = false,
			RRGGBB = true,
			RRGGBBAA = false,
			AARRGGBB = false,
		},
	},
}
