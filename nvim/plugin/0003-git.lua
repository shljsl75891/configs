vim.pack.add({
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
})

vim.g.fugitive_git_executable = "HUSKY=0 git"

local opts = { noremap = true, silent = true }
opts.desc = "Show [G]it [S]tatus"
vim.keymap.set("n", "<leader>gs", "<cmd>vertical G<CR>", opts)
opts.desc = "[G]et left hunk"
vim.keymap.set({ "n", "v" }, "gh", ":diffget //2<CR>", opts)
opts.desc = "[G]et right hunk"
vim.keymap.set({ "n", "v" }, "gl", ":diffget //3<CR>", opts)
opts.desc = "Show [G]it [B]lame for current file"
vim.keymap.set("n", "<leader>gb", "<cmd>G blame<CR>", opts)
