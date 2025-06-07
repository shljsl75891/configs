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

				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:find("/node_modules/", 1, true) then
					return
				end

				local filetype = vim.bo[bufnr].filetype
				local opts = {
					quiet = true,
					timeout_ms = 2000,
					lsp_format = "fallback",
				}

				local ts_filetypes = {
					javascript = true,
					javascriptreact = true,
					typescript = true,
					typescriptreact = true,
				}

				if ts_filetypes[filetype] then
					local client = vim.lsp.get_clients({ name = "ts_ls" })[1]
					if client then
						local prev_pos = vim.api.nvim_win_get_cursor(0)
						client:exec_cmd({
							title = "",
							command = "_typescript.organizeImports",
							arguments = { bufname },
						}, { bufnr = bufnr }, function()
							require("conform").format(opts)
							vim.cmd("noautocmd update")

							local line_count = vim.api.nvim_buf_line_count(bufnr)
							local line = math.min(prev_pos[1], line_count)
							pcall(vim.api.nvim_win_set_cursor, 0, { line, prev_pos[2] })
						end)
						return
					end
				end

				return opts
			end,
		})
	end,
}
