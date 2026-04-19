return {
	{
		"mason-org/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cmd = { "Mason", "MasonToolsInstall", "MasonToolsUpdate" },
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
						"gopls",
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
							suggest = { completeFunctionCalls = false },
						},
						javascript = {
							inlayHints = { enabled = false },
							suggest = { completeFunctionCalls = false },
						},
					},
				},
				eslint = {
					useFlatConfig = false,
					settings = { useFlatConfig = false },
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
				lua_ls = {
					settings = {
						Lua = {
							workspace = { checkThirdParty = false },
							codeLens = { enable = true },
							completion = { callSnippet = "Replace" },
							doc = { privateName = { "^_" } },
							diagnostics = { globals = { "vim" } },
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
						},
					},
				},
			}

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

			vim.lsp.log.set_level("error")

			local installed_servers =
				require("mason-lspconfig").get_installed_servers()
			vim.lsp.enable(installed_servers)

			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local kopts = { buffer = ev.buf, noremap = true, silent = true }
					local snacks = require("snacks")

					kopts.desc = "Get Information of variable/function"
					vim.keymap.set("n", "K", vim.lsp.buf.hover, kopts)
					kopts.desc = "[G]o to [D]efintion of identifier"
					vim.keymap.set("n", "gd", function()
						snacks.picker.lsp_definitions()
					end, kopts)
					kopts.desc = "Find [D]ocument [S]ymbols"
					vim.keymap.set("n", "<leader>ds", function()
						snacks.picker.lsp_symbols()
					end, kopts)
					kopts.desc = "[G]o to [T]ype Defintion of identifier"
					vim.keymap.set("n", "gt", function()
						snacks.picker.lsp_type_definitions()
					end, kopts)
					kopts.desc = "[G]o to [I]mplementation of function"
					vim.keymap.set("n", "gI", function()
						snacks.picker.lsp_implementations()
					end, kopts)
					kopts.desc = "[G]o to All [R]eferences of identifier"
					vim.keymap.set("n", "<leader>rr", function()
						snacks.picker.lsp_references()
					end, kopts)
					kopts.desc = "[R]e[N]ame Symbol"
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, kopts)
					kopts.desc = "List suggested [C]ode [A]ctions"
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, kopts)
					kopts.desc = "Get information about [D][I]agnostics"
					vim.keymap.set("n", "<leader>di", vim.diagnostic.open_float, kopts)
					kopts.desc = "Show LSP signature help"
					vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, kopts)
					kopts.desc = "Go to next [D]iagnostics in the current file"
					vim.keymap.set("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, kopts)
					kopts.desc = "Go to previous [D]iagnostics in the current file"
					vim.keymap.set("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, kopts)
				end,
			})
		end,
	},
}
