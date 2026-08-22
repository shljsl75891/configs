return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = { "ConformInfo", "FormatDisable", "FormatEnable" },
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
				jsonc = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				lua = { "stylua" },
				sql = { "pg_format" },
			},
		},
		config = function(_, opts)
			local conform = require("conform")
			local timeout_ms = 2000

			conform.setup(opts)

			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, { desc = "Disable autoformat-on-save", bang = true })

			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, { desc = "Re-enable autoformat-on-save" })

			-- Autoformat and organize imports on saving file
			vim.api.nvim_create_autocmd("BufWritePre", {
				desc = "Format before save",
				pattern = "*",
				group = vim.api.nvim_create_augroup("FormatConfig", { clear = true }),
				callback = function(ev)
					if vim.g.disable_autoformat or vim.b[ev.buf].disable_autoformat then
						return
					end

					local bufname = vim.api.nvim_buf_get_name(ev.buf)
					if bufname:find("/node_modules/", 1, true) then
						return
					end

					local format_opts = {
						bufnr = ev.buf,
						quiet = true,
						lsp_format = "fallback",
						timeout_ms = timeout_ms,
						stop_after_first = true,
					}

					local client =
						vim.lsp.get_clients({ name = "tsc", bufnr = ev.buf })[1]
					if not client then
						conform.format(format_opts)
						return
					end

					local params = {
						textDocument = { uri = vim.uri_from_bufnr(ev.buf) },
						range = {
							start = { line = 0, character = 0 },
							["end"] = { line = 0, character = 0 },
						},
						context = {
							only = { "source.organizeImports" },
							diagnostics = {},
						},
					}

					local resp = client:request_sync(
						"textDocument/codeAction",
						params,
						timeout_ms,
						ev.buf
					)

					if resp and resp.err then
						vim.notify(resp.err.message, vim.log.levels.ERROR)
						return
					end

					for _, action in ipairs(resp and resp.result or {}) do
						if action.edit then
							vim.lsp.util.apply_workspace_edit(
								action.edit,
								client.offset_encoding
							)
						elseif action.command then
							client:request_sync(
								"workspace/executeCommand",
								action.command,
								timeout_ms,
								ev.buf
							)
						end
					end

					conform.format(format_opts)
				end,
			})
		end,
	},
}
