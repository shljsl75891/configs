-- A function to move selected lines down in visual mode
function Move_lines_down_visual()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local last_line = vim.api.nvim_buf_line_count(0)
	local selected_lines_count = vim.fn.line("'>") - vim.fn.line("'<")
	if current_line + selected_lines_count < last_line then
		vim.api.nvim_command("'<, '>m '>+1")
		vim.api.nvim_command("normal! gv=gv")
	-- When we hit the bottom we just reselect the lines
	else
		vim.api.nvim_command("normal! gv")
	end
end

-- A function to move selected lines up in visual mode
function Move_lines_up_visual()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	if current_line > 1 then
		vim.api.nvim_command("'<, '>m '<-2")
		vim.api.nvim_command("normal! gv=gv")
	-- When we hit the top we just reselect the lines
	else
		vim.api.nvim_command("normal! gv")
	end
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 60 })
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
})

-- For Angular treesitter
if not vim.g.vscode then
	vim.filetype.add({
		pattern = {
			-- Sets the filetype to `htmlangular` if it matches the pattern
			[".*%.component%.html"] = "htmlangular",
		},
	})

	vim.api.nvim_create_autocmd({ "BufWritePre" }, {
		group = vim.api.nvim_create_augroup("TrailingWhitespace", { clear = true }),
		pattern = "*",
		command = [[%s/\s\+$//e]],
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
end

-- Settings for LSP Attached buffer
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local builtin = require("telescope.builtin")
		local opts = { buffer = ev.buf, noremap = true, silent = true }
		-- Lsp APIs
		opts.desc = "Get Information of variable/function"
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover({ border = "solid" })
		end, opts)
		opts.desc = "[G]o to [D]efintion of identifier"
		vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
		opts.desc = "Find [D]ocument [S]ymbols"
		vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, opts)
		opts.desc = "[G]o to [T]ype Defintion of identifier"
		vim.keymap.set("n", "gt", builtin.lsp_type_definitions, opts)
		opts.desc = "[G]o to [I]mplementation of function"
		vim.keymap.set("n", "gI", builtin.lsp_implementations, opts)
		opts.desc = "[G]o to All [R]eferences of identifier"
		vim.keymap.set("n", "<leader>rr", builtin.lsp_references, opts)
		opts.desc = "LSP Signature [H]elp"
		vim.keymap.set("i", "<C-h>", function()
			vim.lsp.buf.signature_help({ border = "solid" })
		end, opts)
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
