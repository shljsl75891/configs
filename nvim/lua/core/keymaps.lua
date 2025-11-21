local opts = { noremap = true, silent = true }

-- Open NetRW plugin
opts.desc = "Open Oil plugin"
vim.keymap.set("n", "-", vim.cmd.Oil)

-- Keeps screen centered
opts.desc = "Scroll down and center screen"
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
opts.desc = "Scroll up and center screen"
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
opts.desc = "Search previous and center"
vim.keymap.set("n", "N", "Nzz", opts)
opts.desc = "Search next and center"
vim.keymap.set("n", "n", "nzz", opts)

-- Move lines
opts.desc = "Move lines down (visual)"
vim.keymap.set("v", "J", ":lua Move_lines_down_visual()<CR>", opts)
opts.desc = "Move lines up (visual)"
vim.keymap.set("v", "K", ":lua Move_lines_up_visual()<CR>", opts)

-- Keeps cursor at front when joining lines
opts.desc = "Join lines and keep cursor in place"
vim.keymap.set("n", "J", "mzJ`z", opts)

-- Delete and paste without overwriting register
opts.desc = "Delete and paste without overwriting register"
vim.keymap.set("x", "<leader>p", [["_dP]], opts)

-- Use system clipboard yanking
opts.desc = "Yank to system clipboard"
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], opts)

-- Terminal normal mode
opts.desc = "Exit terminal mode"
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)

-- Quick find and replace
opts.desc = "Replace all occurrences of word under cursor"
vim.keymap.set(
	"n",
	"<leader>s",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	opts
)

-- Quickfix Navigation
opts.desc = "Previous quickfix item"
vim.keymap.set("n", "<C-Up>", "<cmd>cprev<CR>zz", opts)
opts.desc = "Next quickfix item"
vim.keymap.set("n", "<C-Down>", "<cmd>cnext<CR>zz", opts)

-- Location List Navigation
opts.desc = "Previous location list item"
vim.keymap.set("n", "<M-Up>", "<cmd>lprev<CR>zz", opts)
opts.desc = "Next location list item"
vim.keymap.set("n", "<M-Down>", "<cmd>lnext<CR>zz", opts)

-- Resize windows
opts.desc = "Resize horizontal window -2"
vim.keymap.set("n", "<M-->", ":resize -2<CR>", opts)
opts.desc = "Resize horizontal window +2"
vim.keymap.set("n", "<M-=>", ":resize +2<CR>", opts)
opts.desc = "Resize vertical window -4"
vim.keymap.set("n", "<M-_>", ":vertical resize -4<CR>", opts)
opts.desc = "Resize vertical window +4"
vim.keymap.set("n", "<M-+>", ":vertical resize +4<CR>", opts)

-- Executing Lua
opts.desc = "Execute current buffer"
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", opts)
opts.desc = "Execute current line"
vim.keymap.set("n", "<leader>x", ":.lua <CR>", opts)
opts.desc = "Execute selected lua"
vim.keymap.set("v", "<leader>x", ":lua<CR>", opts)

-- Tab Navigation
opts.desc = "Next tab"
vim.keymap.set("n", "<S-l>", vim.cmd.tabnext, opts)
opts.desc = "Previous tab"
vim.keymap.set("n", "<S-h>", vim.cmd.tabprev, opts)

-- Disable annoying F1 binding
opts.desc = nil
vim.keymap.set("n", "<F1>", ":echo<CR>", opts)
vim.keymap.set("i", "<F1>", "<C-o>:echo<CR>", opts)
