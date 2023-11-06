-- Open Explorer
Remap("n", "<leader>b", vim.cmd.Ex)

-- Horizontal scrolling
Remap("n", "<C-l>", "20zl")
Remap("n", "<C-h>", "20zh")

-- Keeps screen centered
Remap("n", "<C-d>", "<C-d>zz0")
Remap("n", "<C-u>", "<C-u>zz0")
Remap("n", "N", "Nzz")
Remap("n", "n", "nzz")

-- Move lines
Remap("v", "J", ":m '>+1<CR>gv=gv")
Remap("v", "K", ":m '<-2<CR>gv=gv")

-- Keeps cursor at front
Remap("n", "J", "mzJ`z")

-- Delete and paste
Remap("x", "<leader>p", [["_dP]])

-- Use system clipboard yanking
Remap({ "n", "v" }, "<leader>y", [["+y]])

-- Terminal normal mode
Remap("t", "<Esc>", "<C-\\><C-n>")

-- Quick find and replace
Remap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Quickfix Navigation
Remap("n", "<C-Up>", "<cmd>cprev<CR>zz")
Remap("n", "<C-Down>", "<cmd>cnext<CR>zz")

-- Splits resizing
Remap("n", "=", ":resize +2<CR>")
Remap("n", "-", ":resize -2<CR>")
Remap("n", "+", ":vertical resize +2<CR>")
Remap("n", "_", ":vertical resize -2<CR>")
