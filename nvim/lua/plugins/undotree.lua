return {
	"mbbill/undotree",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local undo_tree_opts = {
			undotree_SetFocusWhenToggle = 1,
		}

		for k, v in pairs(undo_tree_opts) do
			vim.g[k] = v
		end

		local opts = { noremap = true, silent = true }
		Remap("n", "<leader>u", vim.cmd.UndotreeToggle, opts)
	end,
}
