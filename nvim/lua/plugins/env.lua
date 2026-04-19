return {
	-- Load dotenv eagerly so env vars are available at startup
	{
		"tpope/vim-dotenv",
		lazy = false,
		config = function()
			vim.cmd("Dotenv " .. vim.fn.stdpath("config") .. "/.env")
		end,
	},
	-- Cloak: lazy — load on env filetypes or explicit commands/keys
	{
		"laytan/cloak.nvim",
		cmd = { "CloakToggle", "CloakPreviewLine", "CloakEnable", "CloakDisable" },
		keys = {
			{
				"<leader>te",
				"<cmd>CloakPreviewLine<cr>",
				desc = "[T]oggle [E]nv Cloak",
			},
			{ "<leader>ct", "<cmd>CloakToggle<cr>", desc = "[T]oggle [C]loak" },
		},
		init = function()
			vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
				pattern = { ".env", ".env.*", "*.env" },
				group = vim.api.nvim_create_augroup("CloakAutoload", { clear = true }),
				callback = function()
					require("lazy").load({ plugins = { "cloak.nvim" } })
				end,
			})
		end,
		opts = {
			enabled = true,
			cloak_character = "*",
			cloak_telescope = true,
		},
	},
}
