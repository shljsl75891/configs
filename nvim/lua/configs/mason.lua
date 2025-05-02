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

-- Enable all installed servers
local installed_servers = require("mason-lspconfig").get_installed_servers()
for _, server in ipairs(installed_servers) do
	vim.lsp.enable(server)
end
