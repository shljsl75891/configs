-- Convienience for remapping
Remap = vim.keymap.set

local globalOptions = {
	-- Mapping space as leader key
	mapleader = " ",
	maplocalleader = " ",
	-- NetRW options
	netrw_banner = 0,
	netrw_bufsettings = "noma nomod nonu nobl nowrap ro",
}

local localOptions = {
	-- Enable block cusor always
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
	expandtab = true,
	softtabstop = 2,
	autoindent = true,
	smartindent = true,
	-- Better options
	colorcolumn = "80",
	termguicolors = true,
	wrap = false,
	undofile = true,
	swapfile = false,
	backup = false,
	scrolloff = 8,
	signcolumn = "yes",
	cursorline = true,
	-- Better windows direction
	splitbelow = true,
	splitright = true,
}

for k, v in pairs(localOptions) do
	vim.opt[k] = v
end

for k, v in pairs(globalOptions) do
	vim.g[k] = v
end
