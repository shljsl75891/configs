return {
	"mbbill/undotree",
	keys = {
		{ "<leader>ut", vim.cmd.UndotreeToggle, desc = "[U]ndo Tree [T]oggle" },
	},
	init = function()
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
