-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			timeout = 60,
		})
	end,
	group = highlight_group,
	pattern = "*",
})

-- Colorscheme setup
return {
	"ellisonleao/gruvbox.nvim",
	lazy = false,
	priority = 1000,
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
				functions = false,
			},
			contrast = "hard",
			overrides = {
				TabnineSuggestion = { link = "Comment" },
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
}
