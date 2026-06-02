return {
	"nvim-mini/mini.cursorword",
	event = "BufReadPost",
	opts = { delay = 800 },
	config = function(_, opts)
		require("mini.cursorword").setup(opts)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "sh" },
			callback = function()
				vim.b.minicursorword_disable = true
			end,
		})
	end,
}
