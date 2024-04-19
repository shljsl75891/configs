-- autocmd for easy navigation markdown files
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.md",
	group = vim.api.nvim_create_augroup("MarkDownNotes", { clear = true }),
	callback = function(ev)
		vim.opt_local.wrap = true
	end,
})

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
