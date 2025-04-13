return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = function()
		local mappings = {
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
		}

		local shift_nums = { "<C-j>", "<C-k>", "<C-h>", "<C-l>" }
		for i, key in ipairs(shift_nums) do
			table.insert(mappings, {
				key,
				function()
					require("harpoon"):list():select(i)
				end,
				desc = "Jump to Harpoon file " .. i,
			})
		end

		return mappings
	end,
	config = function()
		local harpoon = require("harpoon")
		local extensions = require("harpoon.extensions")

		harpoon:extend(extensions.builtins.highlight_current_file())
		harpoon:extend(extensions.builtins.navigate_with_number())

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})
	end,
}
