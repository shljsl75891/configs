return {
	"theprimeagen/harpoon",
	keys = {
		"<leader>a",
		"<leader>m",
		"<a-1>",
		"<a-2>",
		"<a-3>",
		"<a-4>",
	},
	config = function()
		require("harpoon").setup({
			tabline = false,
			menu = {
				width = 50,
			},
		})
		local mark = require("harpoon.mark")
		local ui = require("harpoon.ui")

		Remap("n", "<leader>a", mark.add_file)
		Remap("n", "<leader>m", ui.toggle_quick_menu)

		Remap("n", "<a-1>", function()
			ui.nav_file(1)
		end)
		Remap("n", "<a-2>", function()
			ui.nav_file(2)
		end)
		Remap("n", "<a-3>", function()
			ui.nav_file(3)
		end)
		Remap("n", "<a-4>", function()
			ui.nav_file(4)
		end)
	end,
}
