return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lspconfig = require("lspconfig")
		local lsp_defaults = lspconfig.util.default_config
		local builtin = require("telescope.builtin")

		local function organize_imports()
			local params = {
				command = "_typescript.organizeImports",
				arguments = { vim.api.nvim_buf_get_name(0) },
				title = "",
			}
			vim.lsp.buf.execute_command(params)
		end

		lsp_defaults.capabilities =
			vim.tbl_deep_extend("force", lsp_defaults.capabilities, require("cmp_nvim_lsp").default_capabilities())

		-- Settings for LSP Attached buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			callback = function(event)
				local opts = { buffer = event.buf }
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
			end,
		})

		-- LSPs setup
		lspconfig.tailwindcss.setup({})
		lspconfig.cssls.setup({})
		lspconfig.emmet_ls.setup({})
		lspconfig.lua_ls.setup({
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
							vim.env.VIMRUNTIME,
						},
					},
				},
			},
		})

		lspconfig.tsserver.setup({
			on_attach = function()
				vim.api.nvim_create_user_command("OrganizeImports", organize_imports, {
					desc = "Organize Imports using tsserver",
				})
			end,
		})
	end,
}
