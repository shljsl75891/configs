return {
	"nvim-mini/mini.cursorword",
	version = false,
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("mini.cursorword").setup({ delay = 800 })
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "sh" },
			callback = function()
				vim.b.minicursorword_disable = true
			end,
		})
	end,
}
