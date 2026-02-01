return {
	"saghen/blink.cmp",
	version = "1.*",
	event = "InsertEnter",
	dependencies = { "nvim-mini/mini.icons", "mayromr/blink-cmp-dap" },
	opts = {
		enabled = function()
			return vim.bo.buftype ~= "prompt" or vim.bo.filetype == "dap-repl"
		end,
		keymap = {
			preset = "none",
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-e>"] = { "cancel", "fallback" },
			["<C-space>"] = { "show", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<C-u>"] = { "scroll_documentation_up", "fallback" },
			["<C-d>"] = { "scroll_documentation_down", "fallback" },
		},
		signature = { enabled = false },
		completion = {
			trigger = {
				show_on_keyword = true,
				show_on_trigger_character = true,
				show_on_insert = false,
				show_on_blocked_trigger_characters = { " ", "\n", "\t" },
			},
			list = {
				max_items = 50,
				selection = {
					preselect = true,
					auto_insert = true,
				},
			},
			menu = {
				border = "none",
				winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
				draw = {
					columns = {
						{ "kind_icon" },
						{ "label", "label_description", gap = 1 },
						{ "kind" },
					},
					components = {
						kind_icon = {
							text = function(ctx)
								local kind_icon, _, _ =
									require("mini.icons").get("lsp", ctx.kind)
								return kind_icon .. " "
							end,
							highlight = function(ctx)
								local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
								return hl
							end,
						},
						kind = {
							highlight = function(ctx)
								local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
								return hl
							end,
						},
					},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 150,
				window = {
					border = vim.o.winborder or "rounded",
					winhighlight = "Normal:NormalFloat,FloatBorder:NormalFloat",
				},
			},
		},
		appearance = { nerd_font_variant = "normal" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
				sql = { "snippets", "dadbod", "buffer" },
				["dap-repl"] = { "dap" },
				dapui_watches = { "dap" },
				dapui_hover = { "dap" },
			},
			providers = {
				dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
				dap = { name = "DAP", module = "blink-cmp-dap" },
				-- If buffer source should be available even if `lsp` source is active
				-- lsp = { fallbacks = {"buffer"} },
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
}
