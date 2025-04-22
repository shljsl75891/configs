return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{
			"j-hui/fidget.nvim",
			opts = {
				notification = {
					window = { normal_hl = "Comment", winblend = 0, align = "bottom" },
				},
			},
		},
	},
	config = function()
		require("configs.lsp")
	end,
}
