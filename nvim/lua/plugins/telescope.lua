return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	event = { "VimEnter" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local actions = require("telescope.actions")
		local builtin = require("telescope.builtin")
		-- Keymaps
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind Project [F]iles" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
		vim.keymap.set("n", "<leader>lg", builtin.live_grep, { desc = "[L]ive [G]rep Project-wide" })
		vim.keymap.set("n", "<leader>cr", builtin.registers, { desc = "[C]opy from specific [R]egistrer" })
		vim.keymap.set("n", "<leader>ht", builtin.help_tags, { desc = "Find [H]elp [T]ags" })
		vim.keymap.set("n", "<leader>fsf", function()
			local search_file = vim.fn.input("Name of File > ")
			if search_file ~= "" then
				builtin.find_files({ search_file = search_file })
			end
		end, { desc = "[F]ind [S]pecific [F]ile using its name" })
		vim.keymap.set("n", "<leader>fss", function()
			local search_string = vim.fn.input("Grep string > ")
			if search_string ~= "" then
				builtin.grep_string({ search = search_string })
			end
		end, { desc = "[F]ind [S]pecific [S]tring" })

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

		-- Load fzf-native extensions for capabilites like exact, suffix, prefix matching
		require("telescope").load_extension("fzf")
	end,
}
