vim.diagnostic.config({
	virtual_text = true,
	update_in_insert = false,
	float = {
		focusable = true,
		style = "minimal",
		-- border = "single", "rounded", "shadow", "double", "none", "solid"
		border = "solid",
		source = true,
		header = "",
		prefix = "",
	},
})

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
