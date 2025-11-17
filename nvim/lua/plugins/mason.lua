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
					"dockerfile-language-server",
					-- Formatters
					"prettierd",
					"stylua",
					"pgformatter",
					-- Debug adapters
					"js-debug-adapter",
				},
			},
		},
		"hrsh7th/cmp-nvim-lsp",
		"b0o/schemastore.nvim",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		capabilities.textDocument.completion.completionItem.snippetSupport = true
		capabilities.textDocument.completion.completionItem.resolveSupport = {
			properties = { "documentation", "detail" },
		}

		local servers = {
			ts_ls = {
				init_options = {
					maxTsServerMemory = 1024,
					disableAutomaticTypeAcquisition = true,
					preferences = {
						includeInlayParameterNameHints = "none",
						includeInlayFunctionParameterTypeHints = false,
					},
				},
				settings = {
					typescript = {
						inlayHints = { enabled = false },
						suggest = {
							completeFunctionCalls = false,
						},
					},
					javascript = {
						inlayHints = { enabled = false },
						suggest = {
							completeFunctionCalls = false,
						},
					},
				},
			},
			eslint = {
				settings = {
					run = "onSave",
					nodePath = "",
					workingDirectory = { mode = "location" },
				},
			},
			jsonls = {
				filetypes = { "json", "jsonc" },
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
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
