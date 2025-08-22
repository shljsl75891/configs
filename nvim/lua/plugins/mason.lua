return {
	"mason-org/mason-lspconfig.nvim",
	lazy = true,
	dependencies = {
		{ "mason-org/mason.nvim", opts = {}, cmd = "Mason" },
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			cmd = "MasonToolsInstall",
			opts = {
				ensure_installed = {
					-- Language Servers
					"angularls",
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
					-- Debug adapters
					"js-debug-adapter",
				},
			},
		},
		"hrsh7th/cmp-nvim-lsp",
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
	end,
}
