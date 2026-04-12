vim.pack.add({
	"https://github.com/tpope/vim-dotenv",
	"https://github.com/laytan/cloak.nvim",
})

require("cloak").setup({
	enabled = true,
	cloak_character = "*",
	cloak_telescope = true,
})

vim.keymap.set("n", "<leader>te", function()
	vim.cmd("CloakPreviewLine")
end, { desc = "[T]oggle [E]nv Cloak" })

vim.keymap.set("n", "<leader>ct", function()
	vim.cmd("CloakToggle")
end, { desc = "[T]oggle [C]loak" })

vim.cmd("Dotenv " .. vim.fn.stdpath("config") .. "/.env")
