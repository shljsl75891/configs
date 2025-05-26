return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	enabled = false,
	config = function()
		require("rose-pine").setup({
			variant = "main",
			dark_variant = "main",
			dim_inactive_windows = false,
			extend_background_behind_borders = false,
			styles = {
				bold = true,
				italic = false,
				transparency = true,
			},
			highlight_groups = {
				["@function"] = { bold = true },
				["@function.method"] = { bold = true },
				Comment = { italic = true },
				Visual = { bg = "highlight_med", inherit = false },
				CursorLineNr = { fg = "love" },
				-- Lsp Highlights
				LspReferenceTarget = {
					bg = "highlight_med",
					bold = true,
					underline = true,
				},
				LspSignatureActiveParameter = {
					bg = "highlight_med",
					fg = "love",
					bold = true,
				},
				-- Completion Menu
				Pmenu = { fg = "NONE", bg = "overlay" },
				PmenuSel = { bg = "leaf", fg = "base", bold = true },
				CmpItemAbbrMatch = { fg = "leaf" },
				CmpItemAbbrMatchFuzzy = { link = "CmpItemAbbrMatch" },
				-- Status line highlights
				StatusLine = { fg = "text", bg = "muted", blend = 25 },
				StatusLineNC = { fg = "muted", bg = "muted", blend = 25 },
				-- Floating windows highlights
				NormalFloat = { bg = "highlight_med", blend = 40 },
				FloatBorder = { link = "NormalFloat" },
				-- Telescope borderless highlights
				TelescopeBorder = { fg = "overlay", bg = "overlay" },
				TelescopeNormal = { fg = "subtle", bg = "overlay" },
				TelescopeSelection = { fg = "text", bg = "highlight_med" },
				TelescopeSelectionCaret = { fg = "love", bg = "highlight_med" },
				TelescopeMultiSelection = { fg = "text", bg = "highlight_high" },
				TelescopeTitle = { fg = "base", bg = "love" },
				TelescopePromptTitle = { fg = "base", bg = "pine" },
				TelescopePreviewTitle = { fg = "base", bg = "iris" },
				TelescopePromptNormal = { fg = "text", bg = "surface" },
				TelescopePromptBorder = { fg = "surface", bg = "surface" },
			},
		})
		vim.cmd.colorscheme("rose-pine")
	end,
}
