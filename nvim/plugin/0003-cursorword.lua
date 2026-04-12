vim.pack.add({ "https://github.com/nvim-mini/mini.cursorword" })

require("mini.cursorword").setup({ delay = 800 })

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "sh" },
	callback = function()
		vim.b.minicursorword_disable = true
	end,
})
