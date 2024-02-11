return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local builtin = require("telescope.builtin")
		local lspconfig = require("lspconfig")

		-- LSP completion capabilities
		local capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("cmp_nvim_lsp").default_capabilities()
		)
		capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

		-- Settings for LSP Attached buffer
		local opts = { noremap = true, silent = true }
		local on_attach = function(client, bufnr)
			opts.buffer = bufnr
			-- Lsp APIs
			Remap("n", "K", vim.lsp.buf.hover, opts)
			Remap("n", "gd", builtin.lsp_definitions, opts)
			Remap("n", "<leader>rr", builtin.lsp_references, opts)
			Remap("i", "<C-h>", vim.lsp.buf.signature_help, opts)
			Remap("n", "<leader>rn", vim.lsp.buf.rename, opts)
			Remap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			-- Diagnostics APIs
			Remap("n", "<leader>di", vim.diagnostic.open_float, opts)
			Remap("n", "[d", vim.diagnostic.goto_prev, opts)
			Remap("n", "]d", vim.diagnostic.goto_next, opts)
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			callback = function(event) end,
		})

		local function organize_imports()
			local params = {
				command = "_typescript.organizeImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
				title = "",
			}
			vim.lsp.buf.execute_command(params)
		end

		lspconfig["lua_ls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		lspconfig["eslint"].setup({
			settings = {
				packageManager = "npm",
			},
			on_attach = function(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					command = "EslintFixAll",
				})
			end,
		})

		lspconfig["tsserver"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			commands = {
				OrganizeImports = {
					organize_imports,
					description = "Organize Imports",
				},
			},
		})

		lspconfig["tailwindcss"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			hovers = true,
			suggestions = true,
			root_dir = function(fname)
				local root_pattern = require("lspconfig").util.root_pattern(
					"tailwind.config.cjs",
					"tailwind.config.js",
					"postcss.config.js"
				)
				return root_pattern(fname)
			end,
		})

		lspconfig["cssls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		lspconfig["emmet_ls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
	end,
}
