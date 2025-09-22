return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "mason-org/mason-lspconfig.nvim", opts = {} },
		{
			"j-hui/fidget.nvim",
			opts = {
				progress = { display = { done_ttl = 1, done_icon = "✔" } },
				notification = {
					window = { normal_hl = "Comment", winblend = 0, align = "bottom" },
				},
			},
		},
	},
	config = function()
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = false,
			float = {
				focusable = true,
				style = "minimal",
				source = true,
				header = "",
				prefix = "",
			},
		})

		vim.lsp.set_log_level("error")

		-- Enable all installed servers
		local installed_servers = require("mason-lspconfig").get_installed_servers()
		vim.lsp.enable(installed_servers)
	end,
}
