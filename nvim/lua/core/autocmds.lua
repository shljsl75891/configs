-- autocmd for easy navigation markdown files
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.md",
	callback = function(ev)
		vim.opt_local.wrap = true
		vim.api.nvim_buf_set_keymap(ev.buf, "n", "j", "gj", {})
		vim.api.nvim_buf_set_keymap(ev.buf, "n", "k", "gk", {})
	end,
})
