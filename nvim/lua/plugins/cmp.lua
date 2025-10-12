return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"https://codeberg.org/FelipeLema/cmp-async-path",
		"hrsh7th/cmp-nvim-lsp",
		"nvim-mini/mini.icons",
	},
	config = function()
		local cmp = require("cmp")
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
			formatting = {
				format = function(_, vim_item)
					local icon, hl = require("mini.icons").get("lsp", vim_item.kind)
					vim_item.kind = icon .. " " .. vim_item.kind
					vim_item.kind_hl_group = hl
					return vim_item
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
			}),
		})
		cmp.setup.filetype({ "sql" }, {
			sources = {
				{ name = "vim-dadbod-completion" },
				{ name = "buffer" },
			},
		})
	end,
}
