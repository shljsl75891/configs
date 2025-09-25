return {
	"tpope/vim-dotenv",
	lazy = false,
	config = function()
		vim.cmd("Dotenv " .. vim.fn.stdpath("config") .. "/.env")
	end,
}
