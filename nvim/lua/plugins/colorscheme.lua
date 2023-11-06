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
	"Mofiqul/vscode.nvim",
	priority = 1000,
	config = function()
		local theme = require("vscode")
		local colors = require("vscode.colors").get_colors()
		theme.setup({
			transparent = true,
			italic_comments = false,
			disable_nvimtree_bg = true,
			group_overrides = {
				LspSignatureActiveParameter = { fg = colors.vscBlue, bg = nil, bold = true },
			},
		})
		theme.load()
	end,
}
