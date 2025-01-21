return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = {
		"<leader>a",
		"<leader>m",
		"<C-j>",
		"<C-k>",
		"<C-h>",
		"<C-l>",
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
			ui_width_ratio = 0.45,
		}

		-- Adding buffers in harpoon list
		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "[A]dd current file in harpoon list" })

		-- Toggling harpoon list visibility
		vim.keymap.set("n", "<leader>m", function()
			harpoon.ui:toggle_quick_menu(harpoon:list(), ui_opts)
		end, { desc = "Open Harpoon quick pop-up" })

		-- Opening any buffer in harpoon
		vim.keymap.set("n", "<C-j>", function()
			harpoon:list():select(1)
		end)
		vim.keymap.set("n", "<C-k>", function()
			harpoon:list():select(2)
		end)
		vim.keymap.set("n", "<C-h>", function()
			harpoon:list():select(3)
		end)
		vim.keymap.set("n", "<C-l>", function()
			harpoon:list():select(4)
		end)
	end,
}
