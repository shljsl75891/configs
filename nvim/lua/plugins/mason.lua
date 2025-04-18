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
			local lspconfig = require("lspconfig")
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend(
				"force",
				capabilities,
				require("cmp_nvim_lsp").default_capabilities()
			)

			local default_setup = function(server)
				require("lspconfig")[server].setup({ capabilities = capabilities })
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
							root_dir = lspconfig.util.root_pattern("tsconfig.json"),
							capabilities = capabilities,
						})
					end,
					tailwindcss = function()
						lspconfig["tailwindcss"].setup({
							capabilities = capabilities,
							hovers = true,
							suggestions = true,
							root_dir = function(fname)
								local root_pattern = lspconfig.util.root_pattern(
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
									schemas = require("schemastore").json.schemas(),
									validate = { enable = true },
								},
							},
						})
					end,
				},
			})
		end,
	},
}
