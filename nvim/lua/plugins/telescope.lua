return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.6",
	event = { "VimEnter" },
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local actions = require("telescope.actions")
		local builtin = require("telescope.builtin")
		-- Keymaps
		vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		vim.keymap.set("n", "<leader>lg", builtin.live_grep, {})
		vim.keymap.set("n", "<leader>cp", builtin.registers, {})
		vim.keymap.set("n", "<leader>ht", builtin.help_tags, {})
		vim.keymap.set("n", "<C-f>", function()
			local search_file = vim.fn.input("Name of File > ")
			if search_file ~= "" then
				builtin.find_files({ search_file = search_file })
			end
		end, {})
		vim.keymap.set("n", "<leader>fs", function()
			local search_string = vim.fn.input("Grep string > ")
			if search_string ~= "" then
				builtin.grep_string({ search = search_string })
			end
		end)

		require("telescope").setup({
			defaults = {
				-- could be `horizontal` or `vertical
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						width = 0.85,
						preview_width = 0.45,
					},
					vertical = {
						width = 0.6,
						preview_width = 0.5,
					},
				},
				mappings = {
					n = {
						["<C-w>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
					i = {
						["<C-j>"] = actions.cycle_history_next,
						["<C-k>"] = actions.cycle_history_prev,
					},
				},
			},
			pickers = {
				find_files = {
					find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
				},
				lsp_definitions = { fname_width = 100 },
				lsp_references = { fname_width = 100 },
			},
			extensions = {},
		})
	end,
}
