return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{
			"j-hui/fidget.nvim",
			opts = {
				notification = {
					window = {
						normal_hl = "Comment",
						winblend = 0,
						align = "bottom",
					},
				},
			},
		},
	},
	config = function()
		local builtin = require("telescope.builtin")

		-- border = "single", "rounded", "shadow", "double", "none", "solid"
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "solid" })
		vim.lsp.handlers["textDocument/signatureHelp"] =
			vim.lsp.with(vim.lsp.handlers.signature_help, { border = "solid" })

		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = false,
			float = {
				focusable = true,
				style = "minimal",
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
				local opts = { buffer = ev.buf, noremap = true, silent = true }
				-- Lsp APIs
				opts.desc = "Get Information of variable/function"
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				opts.desc = "[G]o to [D]efintion of identifier"
				vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
				opts.desc = "[G]o to [T]ype Defintion of identifier"
				vim.keymap.set("n", "gt", builtin.lsp_type_definitions, opts)
				opts.desc = "[G]o to [I]mplementation of function"
				vim.keymap.set("n", "gI", builtin.lsp_implementations, opts)
				opts.desc = "[G]o to All [R]eferences of identifier"
				vim.keymap.set("n", "<leader>rr", builtin.lsp_references, opts)
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
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				opts.desc = "Go to previous [D]iagnostics in the current file"
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			end,
		})
	end,
}
