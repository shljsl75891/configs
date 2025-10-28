return {
	"tpope/vim-dotenv",
	lazy = false,
	dependencies = {
		{
			"laytan/cloak.nvim",
			keys = {
				{
					"<leader>te",
					function()
						vim.cmd("CloakPreviewLine")
					end,
					desc = "[T]oggle [E]nv Cloak",
				},
				{
					"<leader>ct",
					function()
						vim.cmd("CloakToggle")
					end,
					desc = "[T]oggle [C]loak",
				},
			},
			opts = {
				enabled = true,
				cloak_character = "*",
				cloak_telescope = true,
			},
		},
	},
	config = function()
		vim.cmd("Dotenv " .. vim.fn.stdpath("config") .. "/.env")
	end,
}
