return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	config = function()
		require("conform").setup({
			-- Define your formatters
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
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				local TIMEOUT = 500
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match("/node_modules/") then
					return
				end
				if
					vim.tbl_contains({
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
					}, vim.bo[bufnr].filetype)
				then
					-- organize imports synchronously before formatting
					vim.lsp.buf_request_sync(0, "workspace/executeCommand", {
						command = "_typescript.organizeImports",
						arguments = { vim.api.nvim_buf_get_name(bufnr) },
					}, TIMEOUT)
				end
				return {
					quiet = true,
					timeout_ms = TIMEOUT,
					lsp_format = "fallback",
				}
			end,
		})
	end,
}
