return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	lazy = false,
	config = function()
		require("mason").setup({})
		require("mason-tool-installer").setup({
			ensure_installed = { "prettierd", "stylua" },
		})
		require("mason-lspconfig").setup({
			ensure_installed = { "eslint", "clangd", "tsserver", "lua_ls", "tailwindcss", "cssls", "emmet_ls" },
			automatic_installation = true,
		})
	end,
}
