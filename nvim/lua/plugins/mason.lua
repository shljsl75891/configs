return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	lazy = false,
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
				"eslint",
				"emmet_ls",
				"clangd",
				"tsserver",
				"lua_ls",
				"tailwindcss",
				"cssls",
				"prettierd",
				"stylua",
			},
		})
		require("mason-lspconfig").setup({
			handlers = {
				default_setup,
				tsserver = function()
					lspconfig["tsserver"].setup({
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
			},
		})
	end,
}
