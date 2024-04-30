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

-- For Angular treesitter
vim.filetype.add({
	pattern = {
		[".*%.component%.html"] = "angular.html", -- Sets the filetype to `angular.html` if it matches the pattern
	},
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "angular.html",
	callback = function()
		vim.treesitter.language.register("angular", "angular.html") -- Register the filetype with treesitter for the `angular` language/parser
	end,
})
