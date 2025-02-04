return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = "cd app && npm install && git restore .",
	dependencies = {
		{
			"dfendr/clipboard-image.nvim",
			keys = {
				{ "<leader>p", "<cmd>PasteImg<cr>", desc = "[P]aste image from clipboard" },
			},
			opts = {
				default = {
					img_dir = "assets",
					img_dir_txt = "/assets",
				},
			},
		},
	},
	init = function()
		vim.g.mkdp_auto_start = 0
		vim.g.mkdp_filetypes = { "markdown" }
		vim.g.mkdp_refresh_slow = 1
	end,
	ft = { "markdown" },
}
