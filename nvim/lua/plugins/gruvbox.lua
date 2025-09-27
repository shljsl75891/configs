return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	lazy = false,
	config = function()
		local theme = require("gruvbox")
		local palette = theme.palette

		theme.setup({
			bold = true,
			italic = {
				strings = false,
				emphasis = true,
				comments = true,
				operators = false,
				folds = false,
			},
			contrast = "hard",
			overrides = {
				LspReferenceTarget = {
					bg = palette.dark2,
					bold = true,
					underline = true,
				},
				LspSignatureActiveParameter = {
					bg = palette.dark3,
					fg = palette.bright_yellow,
					bold = true,
				},
				Pmenu = { fg = "NONE", bg = palette.dark0_soft },
				PmenuSel = {
					bg = palette.dark_aqua_hard,
					fg = palette.bright_aqua,
					bold = true,
				},
				CmpItemAbbrMatch = { fg = palette.bright_aqua },
				CmpItemAbbrMatchFuzzy = { link = "CmpItemAbbrMatch" },
				NormalFloat = { bg = palette.dark0_soft },
				FloatBorder = { link = "NormalFloat" },
				TelescopeNormal = { bg = palette.dark0, fg = palette.dark0 },
				TelescopeResultsNormal = { bg = palette.dark0, fg = palette.light4 },
				TelescopeBorder = { bg = palette.dark0, fg = palette.light0_soft },
				TelescopeSelection = {
					bg = palette.dark0_soft,
					fg = palette.light0_soft,
				},
				TelescopePromptNormal = { bg = palette.dark0_hard },
				TelescopePromptBorder = {
					bg = palette.dark0_hard,
					fg = palette.dark0_hard,
				},
				TelescopePromptTitle = {
					bg = palette.dark0_hard,
					fg = palette.dark0_hard,
				},
				TelescopePreviewTitle = { bg = palette.dark0, fg = palette.dark0 },
				TelescopeResultsTitle = { bg = palette.dark0, fg = palette.dark0 },
				TelescopeMatching = { fg = palette.bright_aqua, bold = true },
				HarpoonNumberActive = { link = "CursorLineNr" },
				HarpoonActive = { link = "CursorLineNr" },
				HarpoonNumberInactive = { bg = nil },
				HarpoonInactive = { bg = nil },
				TabLineFill = { link = "Normal" },
				MiniNotifyNormal = { fg = palette.light2, italic = true },
			},
			transparent_mode = true,
		})
		theme.load()
	end,
}
