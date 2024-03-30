local CustomAutoCommands = vim.api.nvim_create_augroup("MarkDownNotes", { clear = true })

-- autocmd for easy navigation markdown files
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.md",
	group = CustomAutoCommands,
	callback = function(ev)
		vim.opt_local.wrap = true
		vim.api.nvim_buf_set_keymap(ev.buf, "n", "j", "gj", {})
		vim.api.nvim_buf_set_keymap(ev.buf, "n", "k", "gk", {})
	end,
})

-- autocmd for setting filetype to html for ejs
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.ejs",
	group = CustomAutoCommands,
	callback = function()
		vim.opt_local.filetype = "html"
	end,
})
