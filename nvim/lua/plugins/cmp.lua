return {
	"hrsh7th/nvim-cmp",
	dependencies = {
		-- Sources
		"hrsh7th/cmp-buffer",
		"https://codeberg.org/FelipeLema/cmp-async-path",
		"hrsh7th/cmp-nvim-lsp",
		-- Snippet Engine
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		cmp.setup({
			completion = { completeopt = "menu,menuone,noinsert" },
			window = {
				completion = cmp.config.window.bordered({
					border = "none",
					winhighlight = "Normal:Pmenu,CursorLine:PmenuSel",
				}),
				documentation = cmp.config.window.bordered({
					border = vim.o.winborder,
					winhighlight = "Normal:NormalFloat",
				}),
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			mapping = {
				-- Custom bindings
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-e>"] = cmp.mapping.abort(),
				["<C-Space>"] = cmp.mapping.complete(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "async_path" },
				{ name = "buffer" },
				{ name = "luasnip" },
			}),
		})
		cmp.setup.filetype({ "sql" }, {
			sources = {
				{ name = "buffer" },
				{ name = "vim-dadbod-completion" },
			},
		})
	end,
}
