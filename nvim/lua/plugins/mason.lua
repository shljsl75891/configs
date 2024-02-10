return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	lazy = false,
	config = function()
		local lspconfig = require("lspconfig")
		local lsp_capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("cmp_nvim_lsp").default_capabilities()
		)
		lsp_capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

		local default_setup = function(server)
			lspconfig[server].setup({
				capabilities = lsp_capabilities,
			})
		end

		local function organize_imports()
			local params = {
				command = "_typescript.organizeImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
				title = "",
			}
			vim.lsp.buf.execute_command(params)
		end

		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = { "clangd", "tsserver", "lua_ls", "tailwindcss", "cssls", "emmet_ls" },
			handlers = {
				default_setup,
				lua_ls = function()
					lspconfig.lua_ls.setup({
						capabilities = lsp_capabilities,
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT",
								},
								diagnostics = {
									globals = { "vim", "awesome", "client" },
								},
								workspace = {
									library = {
										vim.env.VIMRUNTIME,
									},
								},
							},
						},
					})
				end,
				tsserver = function()
					lspconfig.tsserver.setup({
						capabilities = lsp_capabilities,
						commands = {
							OrganizeImports = {
								organize_imports,
								description = "Organize Imports",
							},
						},
					})
				end,
			},
		})

		require("mason-null-ls").setup({
			ensure_installed = { "stylua", "eslint_d", "prettierd" },
		})
	end,
}
