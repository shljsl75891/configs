return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

		local function organize_imports()
			local params = {
				command = "_typescript.organizeImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
				title = "",
			}
			vim.lsp.buf.execute_command(params)
		end

		local default_setup = function(server)
			require("lspconfig")[server].setup({
				capabilities = capabilities,
			})
		end

		require("mason").setup({})
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- Language Servers
				{ "angularls", autoupdate = false, version = "17.3.2" },
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
		})
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
						commands = {
							OrganizeImports = {
								organize_imports,
								description = "Organize Imports",
							},
						},
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
				lua_ls = function()
					lspconfig["lua_ls"].setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT",
								},
								diagnostics = {
									globals = { "vim" },
								},
								workspace = {
									library = {
										[vim.fn.expand("$VIMRUNTIME/lua")] = true,
										[vim.fn.stdpath("config") .. "/lua"] = true,
									},
								},
							},
						},
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
										fileMatch = { "tsconfig*.json" },
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
}
