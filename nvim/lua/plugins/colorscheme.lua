return {
	{
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 1000,
		enabled = false,
		config = function()
			local theme = require("gruvbox")
			local palette = theme.palette
			theme.setup({
				bold = true,
				italic = {
					strings = false,
					emphasis = false,
					comments = false,
					operators = false,
					folds = false,
					functions = false,
				},
				contrast = "hard",
				overrides = {
					LspSignatureActiveParameter = { bg = nil, fg = palette.bright_yellow, bold = true },
					NormalFloat = { bg = palette.dark0_soft },
					FloatBorder = { link = "NormalFloat" },
					TelescopeNormal = { bg = palette.dark0, fg = palette.dark0 },
					TelescopeResultsNormal = { bg = palette.dark0, fg = palette.light4 },
					TelescopeBorder = { bg = palette.dark0, fg = palette.light0_soft },
					TelescopeSelection = { bg = palette.dark0_soft, fg = palette.light0_soft },
					TelescopePromptNormal = { bg = palette.dark0_hard },
					TelescopePromptBorder = { bg = palette.dark0_hard, fg = palette.dark0_hard },
					TelescopePromptTitle = { bg = palette.dark0_hard, fg = palette.dark0_hard },
					TelescopePreviewTitle = { bg = palette.dark0, fg = palette.dark0 },
					TelescopeResultsTitle = { bg = palette.dark0, fg = palette.dark0 },
					TelescopeMatching = { fg = palette.bright_aqua, bold = true },
				},
				transparent_mode = true,
			})

			theme.load()
		end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		config = function()
			require("rose-pine").setup({
				variant = "main", -- auto, main, moon, or dawn
				dark_variant = "main", -- main, moon, or dawn
				dim_inactive_windows = false,
				extend_background_behind_borders = false,
				styles = {
					bold = true,
					italic = false,
					transparency = true,
				},

				highlight_groups = {
					LspSignatureActiveParameter = { bg = nil, fg = "love", bold = true },
					StatusLine = { fg = "text", bg = "muted", blend = 25 },
					StatusLineNC = { fg = "muted", bg = "muted", blend = 25 },
					NormalFloat = { bg = "surface" },
					FloatBorder = { link = "NormalFloat" },
					TelescopeBorder = { fg = "overlay", bg = "overlay" },
					TelescopeNormal = { fg = "subtle", bg = "overlay" },
					TelescopeSelection = { fg = "text", bg = "highlight_med" },
					TelescopeSelectionCaret = { fg = "love", bg = "highlight_med" },
					TelescopeMultiSelection = { fg = "text", bg = "highlight_high" },
					TelescopeTitle = { fg = "base", bg = "love" },
					TelescopePromptTitle = { fg = "base", bg = "pine" },
					TelescopePreviewTitle = { fg = "base", bg = "iris" },
					TelescopePromptNormal = { fg = "text", bg = "surface" },
					TelescopePromptBorder = { fg = "surface", bg = "surface" },
				},
			})

			vim.cmd.colorscheme("rose-pine")
		end,
	},
}
