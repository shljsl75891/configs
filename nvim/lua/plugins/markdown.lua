return {
	"iamcco/markdown-preview.nvim",
	dependencies = {
		"dfendr/clipboard-image.nvim",
	},
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	build = function()
		vim.fn["mkdp#util#install"]()
	end,
	config = function()
		require("clipboard-image").setup({
			markdown = {
				img_dir_txt = "../img",
			},

			Remap("n", "<leader>p", vim.cmd.PasteImg),
		})
	end,
}
