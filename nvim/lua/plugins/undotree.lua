return {
	"mbbill/undotree",
	keys = {
		{ "<leader>ut", vim.cmd.UndotreeToggle },
	},
	config = function()
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
