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
		local c = require("vscode.colors").get_colors()
		require("vscode").setup({
			transparent = true,
			italic_comments = true,
			disable_nvimtree_bg = true,
			group_overrides = {
				LspSignatureActiveParameter = { fg = c.vscYellow, bg = c.vscDarkBlue },
			},
		})
		require("vscode").load()
	end,
}
