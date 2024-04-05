return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local builtin = require("telescope.builtin")

		-- border = "single", "rounded", "shadow", "double", "none"
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
		vim.lsp.handlers["textDocument/signatureHelp"] =
			vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = false,
			float = {
				focusable = true,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		-- Settings for LSP Attached buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, noremap = true, silent = true }
				-- Lsp APIs
				Remap("n", "K", vim.lsp.buf.hover, opts)
				Remap("n", "gd", builtin.lsp_definitions, opts)
				Remap("n", "gD", builtin.lsp_type_definitions, opts)
				Remap("n", "gI", builtin.lsp_implementations, opts)
				Remap("n", "<leader>rr", builtin.lsp_references, opts)
				Remap("i", "<C-l>", vim.lsp.buf.signature_help, opts)
				Remap("n", "<leader>rn", vim.lsp.buf.rename, opts)
				Remap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				-- Diagnostics APIs
				Remap("n", "<leader>di", vim.diagnostic.open_float, opts)
				Remap("n", "[d", vim.diagnostic.goto_prev, opts)
				Remap("n", "]d", vim.diagnostic.goto_next, opts)
			end,
		})
	end,
}
