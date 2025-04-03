return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = {
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
			end,
			desc = "[A]dd current file to Harpoon list",
		},
		{
			"<leader>m",
			function()
				require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), {
					title = "",
					border = "solid",
					title_pos = "center",
					ui_width_ratio = 0.45,
				})
			end,
			desc = "Open Harpoon quick pop-up",
		},
		{
			"<C-j>",
			function()
				require("harpoon"):list():select(1)
			end,
			desc = "Jump to Harpoon file 1",
		},
		{
			"<C-k>",
			function()
				require("harpoon"):list():select(2)
			end,
			desc = "Jump to Harpoon file 2",
		},
		{
			"<C-h>",
			function()
				require("harpoon"):list():select(3)
			end,
			desc = "Jump to Harpoon file 3",
		},
		{
			"<C-l>",
			function()
				require("harpoon"):list():select(4)
			end,
			desc = "Jump to Harpoon file 4",
		},
	},
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})
	end,
}
