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

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})

		function Harpoon_files()
			local contents = {}
			local marks_length = harpoon:list():length()
			local current_file_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")

			for index = 1, marks_length do
				local item = harpoon:list():get(index)
				local harpoon_file_path = item and item.value or ""
				local file_name = harpoon_file_path == "" and "(empty)"
					or vim.fn.fnamemodify(harpoon_file_path, ":t")

				if current_file_path == harpoon_file_path then
					contents[index] = string.format(
						"%%#HarpoonNumberActive# %s. %%#HarpoonActive#%s ",
						index,
						file_name
					)
				else
					contents[index] = string.format(
						"%%#HarpoonNumberInactive# %s. %%#HarpoonInactive#%s ",
						index,
						file_name
					)
				end
			end

			table.insert(contents, "%#TabLineFill#")

			return table.concat(contents)
		end
		vim.opt.showtabline = 2
		vim.api.nvim_create_autocmd(
			{ "BufEnter", "BufAdd", "BufReadPre", "BufNewFile" },
			{
				callback = function()
					vim.o.tabline = "%!v:lua.Harpoon_files()"
				end,
			}
		)
	end,
}
