return {
	{
		"mason-org/mason.nvim",
		config = true,
		cmd = { "Mason" },
	},
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
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
						"prettier",
						"stylua",
						"sql-formatter",
					},
				},
			},
			{ "neovim/nvim-lspconfig", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
			"b0o/schemastore.nvim",
		},
		config = function()
			local schemastore = require("schemastore")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local servers = {
				emmet_language_server = {
					filetypes = {
						"css",
						"eruby",
						"html",
						"htmldjango",
						"javascriptreact",
						"less",
						"pug",
						"sass",
						"scss",
						"typescriptreact",
						"htmlangular",
					},
				},
				angularls = { filetypes = { "typescript", "htmlangular" } },
				jsonls = {
					filetypes = { "json", "jsonc" },
					settings = {
						json = {
							schemas = schemastore.json.schemas(),
							validate = { enable = true },
						},
					},
				},
			}

			-- Apply config with capabilities
			for server, config in pairs(servers) do
				config.capabilities = capabilities
				vim.lsp.config(server, config)
			end

			-- Enable all installed servers
			local installed_servers =
				require("mason-lspconfig").get_installed_servers()
			for _, server in ipairs(installed_servers) do
				vim.lsp.enable(server)
			end
		end,
	},
}
