return {
	"ellisonleao/gruvbox.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local palette = require("gruvbox").palette
		require("gruvbox").setup({
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
				TabLineFill = { link = "Normal" },
				MiniNotifyNormal = {
					fg = palette.neutral_aqua,
					bold = true,
					italic = true,
				},
				MiniCursorword = { bg = palette.dark2, underline = false },
				MiniCursorwordCurrent = { link = "MiniCursorword" },
				SnacksPickerBorder = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerBoxBorder = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerBoxTitle = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerCurrent = {
					bg = palette.dark0_soft,
					fg = palette.light0_soft,
				},
				SnacksPickerInput = { bg = palette.dark0_hard, fg = palette.light2 },
				SnacksPickerInputNormal = {
					bg = palette.dark0_hard,
					fg = palette.light2,
				},
				SnacksPickerInputBorder = {
					bg = palette.dark0_hard,
					fg = palette.dark0_hard,
				},
				SnacksPickerInputTitle = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerPreview = { bg = palette.dark0, fg = palette.light4 },
				SnacksPickerPreviewNormal = { bg = palette.dark0, fg = palette.light4 },
				SnacksPickerPreviewBorder = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerPreviewTitle = {
					bg = palette.dark0,
					fg = palette.neutral_yellow,
					bold = true,
				},
				SnacksPickerList = { bg = palette.dark0, fg = palette.light2 },
				SnacksPickerListNormal = { bg = palette.dark0, fg = palette.light2 },
				SnacksPickerListBorder = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerTitle = { bg = palette.dark0, fg = palette.dark0 },
				SnacksPickerMatch = { fg = palette.bright_aqua, bold = true },
				-- MiniStatusline mode highlights (bright background, dark foreground)
				MiniStatuslineModeNormal = {
					bg = palette.bright_blue,
					fg = palette.dark0_hard,
					bold = true,
				},
				MiniStatuslineModeInsert = {
					bg = palette.bright_green,
					fg = palette.dark0_hard,
					bold = true,
				},
				MiniStatuslineModeVisual = {
					bg = palette.bright_orange,
					fg = palette.dark0_hard,
					bold = true,
				},
				MiniStatuslineModeReplace = {
					bg = palette.bright_red,
					fg = palette.dark0_hard,
					bold = true,
				},
				MiniStatuslineModeCommand = {
					bg = palette.bright_yellow,
					fg = palette.dark0_hard,
					bold = true,
				},
				MiniStatuslineModeOther = {
					bg = palette.bright_purple,
					fg = palette.dark0_hard,
					bold = true,
				},
				-- MiniStatusline other highlights
				-- Git branch with bright background, dark foreground
				MiniStatuslineDevinfo = {
					bg = palette.bright_purple,
					fg = palette.dark0_hard,
					bold = true,
				},
				-- Filetype: no background, just colored text
				MiniStatuslineFileinfo = { bg = "NONE", fg = palette.light2 },
				MiniStatuslineInactive = { bg = "NONE", fg = palette.dark4 },
				SnacksIndentScope = { fg = palette.faded_yellow },
				DiagnosticWarn = { fg = palette.bright_yellow, bold = true },
				DiagnosticError = { fg = palette.bright_red, bold = true },
				DiagnosticInfo = { fg = palette.bright_blue, bold = true },
				DiagnosticHint = { fg = palette.bright_aqua, bold = true },
				NvimDapViewVirtualText = { fg = palette.light3 },
				NvimDapViewVirtualTextUpdated = {
					fg = palette.bright_yellow,
					bold = true,
				},
			},
			transparent_mode = true,
		})
		require("gruvbox").load()
	end,
}
