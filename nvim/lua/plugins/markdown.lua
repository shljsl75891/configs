return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = "cd app && npm install",
	dependencies = {
		{
			"dfendr/clipboard-image.nvim",
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
