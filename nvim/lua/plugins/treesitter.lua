return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = { "nvim-treesitter/nvim-treesitter-context" },
	opts = {},
	config = function(_, opts)
		require("nvim-treesitter").setup(opts)
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
					vim.log.levels.INFO
				)
				require("nvim-treesitter").install({ lang })
			end,
		})

		require("treesitter-context").setup({
			enable = true,
			mode = "cursor",
			line_numbers = true,
			multiline_threshold = 1,
		})
	end,
}
