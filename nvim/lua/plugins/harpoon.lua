return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = { "BufReadPre", "BufNewFile" },
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

		for i = 1, 9 do
			table.insert(mappings, {
				"<leader>" .. i,
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

		-- Build statusline with Harpoon tabs
		local function build_statusline()
			local list = harpoon:list()
			local tabs = {}
			local current_file = vim.fn.expand("%:t")

			for i = 1, list:length() do
				local item = list:get(i)
				if item then
					local filename = vim.fn.fnamemodify(item.value, ":t")
					local is_active = (filename == current_file)
					local hl = is_active and "%#MiniStatuslineModeOther#"
						or "%#StatusLine#"
					table.insert(
						tabs,
						string.format("%s %d:%s %%#StatusLine# ", hl, i, filename)
					)
				end
			end

			local left = table.concat(tabs, "")
			local right = vim.g.statusline_right

			return left .. "%=" .. right
		end

		-- Update statusline function
		local function update_statusline()
			vim.o.statusline = build_statusline()
		end

		-- Extension to update statusline on Harpoon list changes
		harpoon:extend({
			ADD = update_statusline,
			REMOVE = update_statusline,
			REORDER = update_statusline,
			LIST_CHANGE = update_statusline,
			NAVIGATE = update_statusline,
		})

		harpoon:extend(extensions.builtins.highlight_current_file())

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
			},
		})

		-- Trigger initial statusline update
		update_statusline()
	end,
}
