return {
	"laytan/cloak.nvim",
	ft = { "sh" },
	keys = {
		{ "<leader>uc", vim.cmd.CloakPreviewLine },
		{ "<leader>tc", vim.cmd.CloakToggle },
	},
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
}
