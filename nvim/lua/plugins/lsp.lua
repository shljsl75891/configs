return {
	"mason-org/mason.nvim",
	lazy = false,
	opts = {},
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
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
		"saghen/blink.cmp",
		"b0o/schemastore.nvim",
		"neovim/nvim-lspconfig",
	},
	config = function(_, opts)
		require("mason").setup(opts)
		local capabilities = require("blink.cmp").get_lsp_capabilities({
			workspace = {
				didChangeWatchedFiles = { dynamicRegistration = false },
			},
			textDocument = {
				semanticTokens = vim.NIL,
				completion = {
					completionItem = {
						snippetSupport = true,
						resolveSupport = {
							properties = { "documentation", "detail" },
						},
					},
				},
			},
		})

		local servers = {
			ts_ls = {
				flags = { debounce_text_changes = 150 },
				init_options = {
					maxTsServerMemory = 2560,
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
				useFlatConfig = false,
				settings = {
					useFlatConfig = false,
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

		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = false,
			severity_sort = true,
			float = {
				focusable = true,
				style = "minimal",
				source = false,
				header = "",
				prefix = "",
			},
		})

		vim.lsp.set_log_level("error")

		-- Enable all installed servers
		local installed_servers = require("mason-lspconfig").get_installed_servers()
		vim.lsp.enable(installed_servers)
	end,
}
