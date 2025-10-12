return {
	{
		"nvim-mini/mini.cursorword",
		event = { "BufReadPost", "BufNewFile" },
		version = false,
		opts = { delay = 800 },
	},
	{
		"nvim-mini/mini.icons",
		version = false,
		opts = {},
		specs = {
			{ "nvim-tree/nvim-web-devicons", enabled = false, optional = true },
		},
		lazy = true,
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
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
