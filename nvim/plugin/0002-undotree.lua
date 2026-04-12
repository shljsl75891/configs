vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.cmd.packadd("nvim.undotree")
vim.keymap.set(
	"n",
	"<leader>ut",
	vim.cmd.Undotree,
	{ noremap = true, silent = true, desc = "[U]ndo Tree [T]oggle" }
)
