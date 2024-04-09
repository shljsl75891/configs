return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = {
		"<leader>a",
		"<leader>m",
		"<C-j>",
		"<C-k>",
		"<C-h>",
		"<C-n>",
	},
	config = function()
		local harpoon = require("harpoon")

		-- REQUIRED setup + my custom prefs
		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})

		local ui_opts = {
			title = "",
			border = "solid",
			title_pos = "center",
			ui_width_ratio = 0.35,
		}

		-- Adding buffers in harpoon list
		Remap("n", "<leader>a", function()
			harpoon:list():add()
		end)

		-- Toggling harpoon list visibility
		Remap("n", "<leader>m", function()
			harpoon.ui:toggle_quick_menu(harpoon:list(), ui_opts)
		end)

		-- Opening any buffer in harpoon
		Remap("n", "<C-j>", function()
			harpoon:list():select(1)
		end)
		Remap("n", "<C-k>", function()
			harpoon:list():select(2)
		end)
		Remap("n", "<C-h>", function()
			harpoon:list():select(3)
		end)
		Remap("n", "<C-n>", function()
			harpoon:list():select(4)
		end)
	end,
}
