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
	priority = 1000,
	config = function()
		local theme = require("gruvbox")
		theme.setup({
			terminal_colors = true, -- add neovim terminal colors
			undercurl = true,
			underline = true,
			bold = true,
			italic = {
				strings = false,
				emphasis = false,
				comments = false,
				operators = false,
				folds = false,
			},
			contrast = "hard", -- can be "hard", "soft" or empty string
			overrides = {
				LspSignatureActiveParameter = { bg = nil, fg = "#fabd2f", bold = true },
				NormalFloat = { bg = "#282828" },
			},
			dim_inactive = false,
			transparent_mode = true,
		})
		theme.load()
	end,
}
