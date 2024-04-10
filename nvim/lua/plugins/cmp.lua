return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
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

		require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./snips" } })

		cmp.setup({
			window = {
				completion = cmp.config.window.bordered({
					border = "none",
					winhighlight = "Normal:NormalFloat",
				}),
				documentation = cmp.config.window.bordered({
					border = "rounded",
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
				["<CR>"] = cmp.mapping.confirm({
					select = false,
				}),
				["<C-\\>"] = cmp.mapping.complete(),
				["<C-h>"] = cmp.mapping(function(fallback)
					if luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
				["<C-l>"] = cmp.mapping(function(fallback)
					if luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "async_path" },
				{ name = "buffer" },
				{ name = "luasnip" },
			}),
		})
	end,
}
