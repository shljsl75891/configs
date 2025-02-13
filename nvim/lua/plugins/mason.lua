return {
	{
		"williamboman/mason.nvim",
		cmd = { "Mason" },
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"Saghen/blink.cmp",
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
					},
				},
			},
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local default_setup = function(server)
				require("lspconfig")[server].setup({
					capabilities = capabilities,
				})
			end

			require("mason-lspconfig").setup({
				handlers = {
					default_setup,
					emmet_language_server = function()
						lspconfig["emmet_language_server"].setup({
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
						})
					end,
					angularls = function()
						lspconfig["angularls"].setup({
							filetypes = { "typescript", "htmlangular" },
						})
					end,
					ts_ls = function()
						lspconfig["ts_ls"].setup({
							root_dir = require("lspconfig.util").root_pattern(".git"),
							capabilities = capabilities,
						})
					end,
					tailwindcss = function()
						lspconfig["tailwindcss"].setup({
							capabilities = capabilities,
							hovers = true,
							suggestions = true,
							root_dir = function(fname)
								local root_pattern = require("lspconfig").util.root_pattern(
									"tailwind.config.cjs",
									"tailwind.config.js",
									"postcss.config.js"
								)
								return root_pattern(fname)
							end,
						})
					end,
					jsonls = function()
						lspconfig["jsonls"].setup({
							capabilities = capabilities,
							filetypes = { "json", "jsonc" },
							settings = {
								json = {
									-- Schemas https://www.schemastore.org
									schemas = {
										{
											fileMatch = { "package.json" },
											url = "https://json.schemastore.org/package.json",
										},
										{
											fileMatch = { "jsconfig*.json", "tsconfig*.json" },
											url = "https://json.schemastore.org/tsconfig.json",
										},
										{
											fileMatch = {
												".prettierrc",
												".prettierrc.json",
												"prettier.config.json",
											},
											url = "https://json.schemastore.org/prettierrc.json",
										},
										{
											fileMatch = { ".eslintrc", ".eslintrc.json" },
											url = "https://json.schemastore.org/eslintrc.json",
										},
										{
											fileMatch = { ".babelrc", ".babelrc.json", "babel.config.json" },
											url = "https://json.schemastore.org/babelrc.json",
										},
										{
											fileMatch = { "lerna.json" },
											url = "https://json.schemastore.org/lerna.json",
										},
										{
											fileMatch = { "now.json", "vercel.json" },
											url = "https://json.schemastore.org/now.json",
										},
										{
											fileMatch = {
												".stylelintrc",
												".stylelintrc.json",
												"stylelint.config.json",
											},
											url = "http://json.schemastore.org/stylelintrc.json",
										},
									},
								},
							},
						})
					end,
				},
			})
		end,
	},
}
