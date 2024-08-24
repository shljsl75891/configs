return {
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
					Comment = { italic = true },
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
