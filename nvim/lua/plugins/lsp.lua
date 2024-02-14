return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local builtin = require("telescope.builtin")

		-- Diagnostics config
		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			underline = true,
			update_in_insert = true,
			severity_sort = false,
		})

		-- Settings for LSP Attached buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, noremap = true, silent = true }
				-- Lsp APIs
				Remap("n", "K", vim.lsp.buf.hover, opts)
				Remap("n", "<leader>fr", function()
					require("conform").format({ async = true, lsp_fallback = true })
				end, opts)
				Remap("n", "gd", builtin.lsp_definitions, opts)
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

		-- Remove trailing white spaces
		vim.api.nvim_create_autocmd({ "BufWritePre" }, {
			pattern = "*",
			command = [[%s/\s\+$//e]],
		})
	end,
}
