local format_on_save = function(bufnr)
	local timeout = 2500
	if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
		return
	end

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	if bufname:find("/node_modules/", 1, true) then
		return
	end

	local filetype = vim.bo[bufnr].filetype
	local opts = { quiet = true, timeout_ms = timeout, lsp_format = "fallback" }

	local ts_filetypes = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
	}

	if ts_filetypes[filetype] then
		local client = vim.lsp.get_clients({ name = "ts_ls", bufnr = bufnr })[1]
		if client then
			-- Only preserve cursor if buffer is visible in a window
			local win = vim.fn.bufwinid(bufnr)
			local prev_pos
			if win ~= -1 then
				prev_pos = vim.api.nvim_win_get_cursor(win)
			end

			client:request_sync("workspace/executeCommand", {
				command = "_typescript.organizeImports",
				arguments = { bufname },
			}, timeout, bufnr)

			if win ~= -1 and prev_pos then
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				local line = math.min(prev_pos[1], line_count)
				pcall(vim.api.nvim_win_set_cursor, win, { line, prev_pos[2] })
			end
		end
	end

	return opts
end

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
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
		format_on_save = format_on_save,
	},
}
