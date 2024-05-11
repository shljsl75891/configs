local globalOptions = {
	-- Mapping space as leader key
	mapleader = " ",
	maplocalleader = " ",
	-- NetRW options
	netrw_banner = 0,
	netrw_browse_split = 0,
	netrw_bufsettings = "noma nomod nu nobl nowrap ro rnu",
}

local localOptions = {
	-- Block cursor always
	guicursor = "",
	-- Enable relativenumber line
	number = true,
	relativenumber = true,
	numberwidth = 2,
	-- Better searching highlights
	hlsearch = false,
	incsearch = true,
	ignorecase = true,
	smartcase = true,
	-- Better indentation
	shiftwidth = 2,
	tabstop = 2,
	smarttab = true,
	mouse = "",
	expandtab = true,
	softtabstop = 2,
	autoindent = true,
	smartindent = true,
	-- Better options
	termguicolors = true,
	wrap = false,
	undofile = true,
	undodir = os.getenv("HOME") .. "/.vim/undodir",
	swapfile = false,
	backup = false,
	scrolloff = 8,
	signcolumn = "yes",
	colorcolumn = "80",
	updatetime = 40,
	cursorline = true,
	-- Better windows direction
	splitbelow = true,
	splitright = true,
	-- auto refresh
	autoread = true,
	autowrite = true,
	-- items in completion menu
	pumheight = 8,
	-- disable vi compatibilty
	compatible = false,
	-- show filetype in default status line
	statusline = "%f%=%{&filetype}",
}

for k, v in pairs(localOptions) do
	vim.opt[k] = v
end

for k, v in pairs(globalOptions) do
	vim.g[k] = v
end
