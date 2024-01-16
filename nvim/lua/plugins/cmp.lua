return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		-- Sources
		"hrsh7th/cmp-buffer",
		"FelipeLema/cmp-async-path",
		"hrsh7th/cmp-nvim-lsp",
		-- Snippet Engine
		"L3MON4D3/LuaSnip",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		cmp.setup({
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
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<C-l>"] = cmp.mapping.complete(),
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "async_path" },
				{ name = "buffer" },
			}),
		})
	end,
}
