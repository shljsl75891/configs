-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			timeout = 60,
		})
	end,
	group = highlight_group,
	pattern = "*",
})

-- Colorscheme setup
return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local theme = require("tokyonight")
		theme.setup({
			style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
			transparent = true, -- Enable this to disable setting the background color
			terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
			styles = {
				comments = { italic = true },
				keywords = { bold = true, italic = true },
				functions = { italic = true },
				variables = {},
				sidebars = "dark", -- style for sidebars, see below
				floats = "dark", -- style for floating windows
			},
			hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
			on_highlights = function(hl, c)
				local prompt = "#2D3149"
				hl.LspSignatureActiveParameter = {
					fg = c.magenta2,
					bg = c.none,
					bold = true,
				}
				hl.TelescopeNormal = {
					bg = c.bg_dark,
					fg = c.fg_dark,
				}
				hl.TelescopeBorder = {
					bg = c.bg_dark,
					fg = c.bg_dark,
				}
				hl.TelescopePromptNormal = {
					bg = prompt,
				}
				hl.TelescopePromptBorder = {
					bg = prompt,
					fg = prompt,
				}
				hl.TelescopePromptTitle = {
					bg = prompt,
					fg = prompt,
				}
				hl.TelescopePreviewTitle = {
					bg = c.bg_dark,
					fg = c.bg_dark,
				}
				hl.TelescopeResultsTitle = {
					bg = c.bg_dark,
					fg = c.bg_dark,
				}
				hl.diffAdded = { link = "DiffAdd" }
				hl.diffRemoved = { link = "DiffDelete" }
			end,
		})
		theme.load()
	end,
}

--[[ return {
	"",
	lazy = false,
	priority = 1000,
	config = function()
		local theme = require("gruvbox")
		local palette = theme.palette
		theme.setup({
			bold = true,
			italic = {
				strings = false,
				emphasis = true,
				comments = true,
				operators = false,
				folds = false,
				functions = true,
			},
			contrast = "hard",
			overrides = {
				LspSignatureActiveParameter = {
					bg = nil,
					fg = palette.bright_yellow,
					bold = true,
				},
				NormalFloat = {
					bg = palette.dark0_soft,
				},
				TelescopeNormal = {
					bg = palette.dark0,
					fg = palette.dark0,
				},
				TelescopeResultsNormal = {
					bg = palette.dark0,
					fg = palette.light4,
				},
				TelescopeBorder = {
					bg = palette.dark0,
					fg = palette.light0_soft,
				},
				TelescopeSelection = {
					bg = palette.dark0_soft,
					fg = palette.light0_soft,
				},
				TelescopePromptNormal = {
					bg = palette.dark0_hard,
				},
				TelescopePromptBorder = {
					bg = palette.dark0_hard,
					fg = palette.dark0_hard,
				},
				TelescopePromptTitle = {
					bg = palette.dark0_hard,
					fg = palette.dark0_hard,
				},
				TelescopePreviewTitle = {
					bg = palette.dark0,
					fg = palette.dark0,
				},
				TelescopeResultsTitle = {
					bg = palette.dark0,
					fg = palette.dark0,
				},
				TelescopeMatching = {
					fg = palette.bright_aqua,
					bold = true,
				},
			},
			transparent_mode = true,
		})

		theme.load()
	end,
} ]]
