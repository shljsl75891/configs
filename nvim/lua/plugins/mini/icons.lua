return {
	"nvim-mini/mini.icons",
	lazy = false,
	priority = 900,
	config = function()
		package.preload["nvim-web-devicons"] = function()
			require("mini.icons").mock_nvim_web_devicons()
			return package.loaded["nvim-web-devicons"]
		end
		require("mini.icons").setup()
	end,
}
