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
				HarpoonNumberActive = { link = "CursorLineNr" },
				HarpoonActive = { link = "CursorLineNr" },
				HarpoonNumberInactive = { bg = nil },
				HarpoonInactive = { bg = nil },
				TabLineFill = { link = "Normal" },
				MiniNotifyNormal = { fg = palette.light2, italic = true },
				MiniCursorword = { bg = palette.dark2, underline = false },
				MiniCursorwordCurrent = { link = "MiniCursorword" },
				MiniPickBorderText = {
					bg = palette.neutral_aqua,
					fg = palette.dark0,
					bold = true,
				},
				MiniPickIconDirectory = { link = "Pmenu" },
				MiniPickIconFile = { link = "Pmenu" },
				MiniPickNormal = { link = "Pmenu" },
				MiniPickHeader = { link = "Title" },
				MiniPickMatchCurrent = { link = "Visual" },
				MiniPickMatchMarked = { bg = palette.neutral_purple },
				MiniPickMatchRanges = { link = "FloatTitle" },
				MiniPickPreviewLine = { link = "CursorLine" },
				MiniPickPreviewRegion = { link = "PmenuThumb" },
				MiniPickPrompt = { link = "Pmenu" },
			},
			transparent_mode = true,
		})
		theme.load()
	end,
}
