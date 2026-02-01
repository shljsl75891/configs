return {
	"echasnovski/mini.statusline",
	version = "*",
	event = "VeryLazy",
	dependencies = { "ThePrimeagen/harpoon" },
	config = function()
		local statusline = require("mini.statusline")
		local harpoon = require("harpoon")

		local function custom_active()
			-- Mode section
			local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })

			-- Git branch
			local branch = vim.fn.FugitiveStatusline() or ""

			-- Harpoon tabs
			local current_path = vim.fn.expand("%:p")
			local tabs = {}

			for i = 1, harpoon:list():length() do
				local item = harpoon:list():get(i)
				if item then
					local is_active = vim.fn.fnamemodify(item.value, ":p") == current_path
					local hl = is_active and "HarpoonStatuslineActive"
						or "HarpoonStatuslineInactive"
					local filename = vim.fn.fnamemodify(item.value, ":t")
					table.insert(
						tabs,
						string.format("%%#%s#%d:%s %%#StatusLine#", hl, i, filename)
					)
				end
			end

			local harpoon_tabs = table.concat(tabs, "")

			-- Build statusline string
			local parts = {}

			-- Mode
			if mode ~= "" then
				table.insert(
					parts,
					string.format("%%#%s# %s %%#StatusLine#", mode_hl, mode)
				)
			end

			-- Center for harpoon
			table.insert(parts, "%=")
			if harpoon_tabs ~= "" then
				table.insert(parts, harpoon_tabs)
			end

			-- Right alignment
			table.insert(parts, "%=")

			-- Git branch
			if branch ~= "" then
				table.insert(
					parts,
					string.format("%%#MiniStatuslineDevinfo# %s %%#StatusLine#", branch)
				)
			end

			-- Filetype
			table.insert(
				parts,
				string.format(" %%#MiniStatuslineFileinfo#%%y%%#StatusLine#")
			)

			return table.concat(parts)
		end

		-- Setup
		statusline.setup({
			content = {
				active = custom_active,
				inactive = function()
					return "%#MiniStatuslineInactive# %F"
				end,
			},
			use_icons = true,
		})

		-- Hook into harpoon events for immediate updates
		harpoon:extend({
			ADD = function()
				vim.cmd("redrawstatus")
			end,
			REMOVE = function()
				vim.cmd("redrawstatus")
			end,
			REORDER = function()
				vim.cmd("redrawstatus")
			end,
			LIST_CHANGE = function()
				vim.cmd("redrawstatus")
			end,
			NAVIGATE = function()
				vim.cmd("redrawstatus")
			end,
		})
	end,
}
