-- Open Explorer
vim.keymap.set("n", "<leader>b", vim.cmd.Oil)

-- Keeps screen centered
vim.keymap.set("n", "<C-d>", "<C-d>zz0")
vim.keymap.set("n", "<C-u>", "<C-u>zz0")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "n", "nzz")

-- Move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keeps cursor at front
vim.keymap.set("n", "J", "mzJ`z")

-- Delete and paste
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Use system clipboard yanking
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

-- Terminal normal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- Quick find and replace
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Quickfix Navigation
vim.keymap.set("n", "<C-Up>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<C-Down>", "<cmd>cnext<CR>zz")

-- Resizing windows
vim.keymap.set("n", "<M-->", ":resize -2<CR>")
vim.keymap.set("n", "<M-=>", ":resize +2<CR>")
vim.keymap.set("n", "<M-_>", ":vertical resize -4<CR>")
vim.keymap.set("n", "<M-+>", ":vertical resize +4<CR>")

-- Disable Annoying remap
vim.keymap.set("n", "<F1>", "<Nop>")
