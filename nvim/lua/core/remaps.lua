-- Open NetRW
vim.keymap.set("n", "-", vim.cmd.Ex)

-- Keeps screen centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "n", "nzz")

-- Move lines
vim.keymap.set("v", "J", ":lua Move_lines_down_visual()<CR>")
vim.keymap.set("v", "K", ":lua Move_lines_up_visual()<CR>")

-- Keeps cursor at front
vim.keymap.set("n", "J", "mzJ`z")

-- Delete and paste
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Use system clipboard yanking
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

-- Terminal normal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- Quick find and replace
vim.keymap.set(
	"n",
	"<leader>s",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace all occurrences of word under the cursor" }
)

-- Quickfix Navigation
vim.keymap.set("n", "<C-Up>", "<cmd>cprev<CR>zz", { desc = "Go to previous entry in quickfix list" })
vim.keymap.set("n", "<C-Down>", "<cmd>cnext<CR>zz", { desc = "Go to next entry in quickfix list" })

-- Resizing windows
vim.keymap.set("n", "<M-->", ":resize -2<CR>", { desc = "Decrease size of horizontal window" })
vim.keymap.set("n", "<M-=>", ":resize +2<CR>", { desc = "Increase size of horizontal window" })
vim.keymap.set("n", "<M-_>", ":vertical resize -4<CR>", { desc = "Decrease size of vertical window" })
vim.keymap.set("n", "<M-+>", ":vertical resize +4<CR>", { desc = "Increase size of vertical window" })

-- Horizontal Scrolling
vim.keymap.set("n", "<C-Left>", "15zh", { desc = "Scroll to left" })
vim.keymap.set("n", "<C-Right>", "15zl", { desc = "Scroll to right" })
