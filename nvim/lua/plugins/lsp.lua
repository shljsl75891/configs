return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "mason-org/mason-lspconfig.nvim", opts = {} },
		{
			"echasnovski/mini.notify",
			version = false,
			opts = {
				window = {
					config = {
						anchor = "SE",
						border = "none",
						col = vim.o.columns,
						row = vim.o.lines - vim.o.cmdheight - 2,
					},
					winblend = 0,
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
		for _, server in ipairs(installed_servers) do
			vim.lsp.enable(server)
		end
	end,
}
