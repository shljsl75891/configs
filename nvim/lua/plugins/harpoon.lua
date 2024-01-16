return {
	"theprimeagen/harpoon",
	config = function()
		local mark = require("harpoon.mark")
		local ui = require("harpoon.ui")

		Remap("n", "<leader>a", mark.add_file)
		Remap("n", "<leader>m", ui.toggle_quick_menu)

		Remap("n", "<C-j>", function()
			ui.nav_file(1)
		end)
		Remap("n", "<C-k>", function()
			ui.nav_file(2)
		end)
		Remap("n", "<C-n>", function()
			ui.nav_file(3)
		end)
		Remap("n", "<C-m>", function()
			ui.nav_file(4)
		end)
	end,
}
