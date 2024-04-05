return {
	"laytan/cloak.nvim",
	keys = {
		{ "<leader>uc", vim.cmd.CloakPreviewLine },
	},
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
}
