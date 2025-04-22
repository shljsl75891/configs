local lspconfig = require("lspconfig")
local capabilities = vim.tbl_deep_extend(
	"force",
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)

require("mason-lspconfig").setup({
	handlers = {
		function(server)
			require("lspconfig")[server].setup({ capabilities = capabilities })
		end,
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
