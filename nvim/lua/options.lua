-- Mapping space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- NetRW options
vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 0
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro rnu"

-- Block cursor always
vim.opt.guicursor = ""
-- Enable relativenumber line
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4
-- Better searching highlights
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Better indentation
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smarttab = true
vim.opt.mouse = "nv"
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
-- Better options
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.colorcolumn = "80"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 40
vim.opt.cursorline = true
-- Better windows direction
vim.opt.splitbelow = true
vim.opt.splitright = true
-- auto refresh
vim.opt.autoread = true
vim.opt.autowrite = true
-- items in completion menu
vim.opt.pumheight = 25
-- disable vi compatibilty
vim.opt.compatible = false
-- border = "single", "rounded", "shadow", "double", "none", "solid"
vim.opt.winborder = "solid"
-- treesitter indentation
vim.opt.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
