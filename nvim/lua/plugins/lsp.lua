return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local builtin = require("telescope.builtin")

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
				Remap("i", "<C-h>", vim.lsp.buf.signature_help, opts)
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
