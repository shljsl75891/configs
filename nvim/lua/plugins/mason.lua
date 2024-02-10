return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	lazy = false,
	config = function()
		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = { "clangd", "tsserver", "lua_ls", "tailwindcss", "cssls", "emmet_ls" },
			automatic_installation = true,
		})

		require("mason-null-ls").setup({
			ensure_installed = { "stylua", "eslint_d", "prettierd" },
		})
	end,
}
