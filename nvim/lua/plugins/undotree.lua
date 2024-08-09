return {
	"mbbill/undotree",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{ "<leader>ut", vim.cmd.UndotreeToggle },
	},
	config = function()
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
