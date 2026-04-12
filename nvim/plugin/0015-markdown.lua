vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if
			name == "markdown-preview.nvim"
			and (kind == "install" or kind == "update")
		then
			if not ev.data.active then
				vim.cmd.packadd("markdown-preview.nvim")
			end
			vim.fn["mkdp#util#install"]()
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown" },
	group = vim.api.nvim_create_augroup("MarkdownPlugins", { clear = true }),
	callback = function()
		vim.g.mkdp_auto_start = 0
		vim.g.mkdp_filetypes = { "markdown" }
		vim.g.mkdp_refresh_slow = 1

		vim.pack.add({
			"https://github.com/iamcco/markdown-preview.nvim",
			"https://github.com/dfendr/clipboard-image.nvim",
		})

		require("clipboard-image").setup({
			default = { img_dir = "assets", img_dir_txt = "/assets" },
		})

		vim.keymap.set(
			"n",
			"<leader>p",
			"<cmd>PasteImg<cr>",
			{ noremap = true, silent = true, desc = "[P]aste image from clipboard" }
		)
	end,
})
