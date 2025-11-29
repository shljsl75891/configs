return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"https://codeberg.org/FelipeLema/cmp-async-path",
		"hrsh7th/cmp-nvim-lsp",
		"nvim-mini/mini.icons",
		"rcarriga/cmp-dap",
	},
	config = function()
		local cmp = require("cmp")

		cmp.setup({
			enabled = function()
				return vim.api.nvim_get_option_value("buftype", { buf = 0 }) ~= "prompt"
					or require("cmp_dap").is_dap_buffer()
			end,
			completion = {
				completeopt = "menu,menuone,noinsert",
				keyword_length = 1,
			},
			performance = {
				debounce = 150,
				throttle = 60,
				fetching_timeout = 500,
				max_view_entries = 50,
			},
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
				["<C-u>"] = cmp.mapping.scroll_docs(-5),
				["<C-d>"] = cmp.mapping.scroll_docs(5),
			},
			sources = cmp.config.sources({
				{
					name = "nvim_lsp",
					priority = 1000,
					max_item_count = 30,
					keyword_length = 1,
				},
				{
					name = "async_path",
					priority = 300,
					keyword_length = 2,
					max_item_count = 10,
				},
				{
					name = "buffer",
					priority = 100,
					keyword_length = 3,
					max_item_count = 10,
					option = {
						get_bufnrs = function()
							local bufs = {}
							for _, win in ipairs(vim.api.nvim_list_wins()) do
								bufs[vim.api.nvim_win_get_buf(win)] = true
							end
							return vim.tbl_keys(bufs)
						end,
					},
				},
			}),
		})
		cmp.setup.filetype({ "sql" }, {
			sources = {
				{ name = "vim-dadbod-completion", priority = 1000 },
				{ name = "buffer", priority = 100, keyword_length = 1 },
			},
		})
		cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
			sources = {
				{ name = "dap" },
			},
		})
	end,
}
