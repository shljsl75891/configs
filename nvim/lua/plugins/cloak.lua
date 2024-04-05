return {
	"laytan/cloak.nvim",
	ft = { "sh" },
	keys = {
		{ "<leader>uc", vim.cmd.CloakPreviewLine },
	},
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
}
