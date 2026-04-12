vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "nvim-treesitter" and kind == "update" then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

require("nvim-treesitter").setup()

vim.opt.foldmethod = "expr"
vim.opt.foldcolumn = "auto"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match) or args.match
		local available = require("nvim-treesitter").get_available()

		if not vim.tbl_contains(available, lang) then
			return
		end

		local ok = pcall(vim.treesitter.start, args.buf, lang)
		if ok then
			vim.bo[args.buf].indentexpr =
				"v:lua.require'nvim-treesitter'.indentexpr()"
			return
		end
		vim.notify(
			"Installing treesitter parser: "
				.. lang
				.. "\nRun :e! after installation to activate the parser",
			vim.log.levels.WARN
		)
		require("nvim-treesitter").install({ lang })
	end,
})
