return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	enabled = false,
	config = function()
		require("configs.rosepine")
	end,
}
