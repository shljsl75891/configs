return {
	{
		"williamboman/mason.nvim",
		config = true,
		cmd = { "Mason" },
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = {
						-- Language Servers
						{ "angularls", version = "14.2.0" },
						"emmet_language_server",
						"eslint-lsp",
						"jsonls",
						"ts_ls",
						"lua_ls",
						"tailwindcss",
						"cssls",
						-- Formatters
						"prettierd",
						"stylua",
						"sql-formatter",
					},
				},
			},
			{ "neovim/nvim-lspconfig", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
			"b0o/schemastore.nvim",
		},
		config = function()
			require("configs.mason")
		end,
	},
}
