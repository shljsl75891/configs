return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		formatters_by_ft = {
			javascript = { "prettierd" },
			typescript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescriptreact = { "prettierd" },
			css = { "prettierd" },
			scss = { "prettierd" },
			html = { "prettierd" },
			htmlangular = { "prettierd" },
			json = { "prettierd" },
			yaml = { "prettierd" },
			markdown = { "prettierd" },
			lua = { "stylua" },
			sql = { "sql_formatter" },
		},
		formatters = {
			sql_formatter = {
				args = {
					"-l",
					"plsql",
					"-c",
					os.getenv("HOME") .. "/personal/configs/.sql-formatter.json",
				},
			},
		},
	},
}
