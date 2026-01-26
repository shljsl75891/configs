-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank({ timeout = 80 })
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
})

-- For Angular treesitter
vim.filetype.add({
	pattern = {
		-- Sets the filetype to `htmlangular` if it matches the pattern
		[".*%.component%.html"] = "htmlangular",
	},
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, { desc = "Re-enable autoformat-on-save" })

-- Settings for LSP Attached buffer
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local opts = { buffer = ev.buf, noremap = true, silent = true }
		local snacks = require("snacks")

		local client = vim.lsp.get_clients({ bufnr = ev.buf })[1]

		if client then
			client.server_capabilities.semanticTokensProvider = nil
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Lsp APIs
		opts.desc = "Get Information of variable/function"
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		opts.desc = "[G]o to [D]efintion of identifier"
		vim.keymap.set("n", "gd", function()
			snacks.picker.lsp_definitions()
		end, opts)
		opts.desc = "Find [D]ocument [S]ymbols"
		vim.keymap.set("n", "<leader>ds", function()
			snacks.picker.lsp_symbols()
		end, opts)
		opts.desc = "[G]o to [T]ype Defintion of identifier"
		vim.keymap.set("n", "gt", function()
			snacks.picker.lsp_type_definitions()
		end, opts)
		opts.desc = "[G]o to [I]mplementation of function"
		vim.keymap.set("n", "gI", function()
			snacks.picker.lsp_implementations()
		end, opts)
		opts.desc = "[G]o to All [R]eferences of identifier"
		vim.keymap.set("n", "<leader>rr", function()
			snacks.picker.lsp_references()
		end, opts)
		opts.desc = "LSP Signature [H]elp"
		vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
		opts.desc = "[R]e[N]ame Symbol"
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		opts.desc = "List suggested [C]ode [A]ctions"
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		-- Diagnostics APIs
		opts.desc = "Get information about [D][I]agnostics"
		vim.keymap.set("n", "<leader>di", vim.diagnostic.open_float, opts)
		opts.desc = "Go to next [D]iagnostics in the current file"
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, opts)
		opts.desc = "Go to previous [D]iagnostics in the current file"
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, opts)
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	desc = "Format before save",
	pattern = "*",
	group = vim.api.nvim_create_augroup("FormatConfig", { clear = true }),
	callback = function(ev)
		local conform_opts = {
			bufnr = ev.buf,
			quiet = true,
			lsp_format = "fallback",
			timeout_ms = 2000,
			stop_after_first = true,
		}

		if vim.g.disable_autoformat or vim.b[ev.buf].disable_autoformat then
			return
		end

		local bufname = vim.api.nvim_buf_get_name(ev.buf)
		if bufname:find("/node_modules/", 1, true) then
			return
		end

		local client = vim.lsp.get_clients({ name = "ts_ls", bufnr = ev.buf })[1]

		if not client then
			require("conform").format(conform_opts)
			return
		end

		local request_result = client:request_sync("workspace/executeCommand", {
			command = "_typescript.organizeImports",
			arguments = { vim.api.nvim_buf_get_name(ev.buf) },
		})

		if request_result and request_result.err then
			vim.notify(request_result.err.message, vim.log.levels.ERROR)
			return
		end

		require("conform").format(conform_opts)
	end,
})

-- Rename files using LSP operations with snacks plugin
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "netrw" },
	group = vim.api.nvim_create_augroup("NetrwOnRename", { clear = true }),
	callback = function()
		vim.keymap.set("n", "R", function()
			local original_file_path = vim.b.netrw_curdir
				.. "/"
				.. vim.fn["netrw#Call"]("NetrwGetWord")

			vim.ui.input(
				{ prompt = "Move/rename to:", default = original_file_path },
				function(target_file_path)
					if target_file_path and target_file_path ~= "" then
						local file_exists = vim.uv.fs_access(target_file_path, "W")

						if not file_exists then
							vim.uv.fs_rename(original_file_path, target_file_path)

							require("snacks").rename.on_rename_file(
								original_file_path,
								target_file_path
							)
						else
							vim.notify(
								"File '" .. target_file_path .. "' already exists! Skipping...",
								vim.log.levels.ERROR
							)
						end

						-- Refresh netrw
						vim.cmd(":Ex " .. vim.b.netrw_curdir)
					end
				end
			)
		end, { remap = true, buffer = true })
	end,
})
