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
		require("tokyonight").setup({
			style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
			transparent = true, -- Enable this to disable setting the background color
			terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
			styles = {
				comments = { italic = false },
				keywords = { italic = false },
				functions = { bold = true, italic = false },
				variables = {},
				sidebars = "dark", -- style for sidebars, see below
				floats = "dark", -- style for floating windows
			},
			on_highlights = function(highlights, colors)
				highlights.LspSignatureActiveParameter = {
					bg = nil,
					fg = colors.cyan,
					bold = true,
				}
				local prompt = "#2d3149"
				highlights.TelescopeNormal = {
					bg = colors.bg_dark,
					fg = colors.fg_dark,
				}
				highlights.TelescopeBorder = {
					bg = colors.bg_dark,
					fg = colors.bg_dark,
				}
				highlights.TelescopePromptNormal = {
					bg = prompt,
				}
				highlights.TelescopePromptBorder = {
					bg = prompt,
					fg = prompt,
				}
				highlights.TelescopePromptTitle = {
					bg = prompt,
					fg = prompt,
				}
				highlights.TelescopePreviewTitle = {
					bg = colors.bg_dark,
					fg = colors.bg_dark,
				}
				highlights.TelescopeResultsTitle = {
					bg = colors.bg_dark,
					fg = colors.bg_dark,
				}
			end,
		})

		vim.cmd.colorscheme("tokyonight")
	end,
}
