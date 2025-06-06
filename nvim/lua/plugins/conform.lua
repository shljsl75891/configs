return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	config = function()
		require("conform").setup({
			-- Define your formatters
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				htmlangular = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
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
				local TIMEOUT = 2000
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match("/node_modules/") then
					return
				end
				local opts = {
					quiet = true,
					timeout_ms = TIMEOUT,
					lsp_format = "fallback",
				}
				if
					vim.tbl_contains({
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
					}, vim.bo[bufnr].filetype)
				then
					-- organize imports, and then format
					vim.lsp.buf_request(0, "workspace/executeCommand", {
						command = "_typescript.organizeImports",
						arguments = { vim.api.nvim_buf_get_name(bufnr) },
					}, function()
						require("conform").format(opts)
						vim.cmd("noautocmd update")
					end)
				else
					return opts
				end
			end,
		})
	end,
}
