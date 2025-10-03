return {
	"tpope/vim-dotenv",
	lazy = false,
	keys = {
		{
			"<leader>te",
			function()
				vim.cmd("CloakToggle")
			end,
			desc = "[T]oggle [E]nv Cloak",
		},
	},
	dependencies = {
		{
			"laytan/cloak.nvim",
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
