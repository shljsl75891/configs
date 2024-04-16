return {
	"j-hui/fidget.nvim",
	event = { "LspAttach" },
	opts = {
		notification = {
			-- Options related to the notification window and buffer
			window = {
				normal_hl = "Comment", -- Base highlight group in the notification window
				winblend = 0, -- Background color opacity in the notification window
				border = "none", -- Border around the notification window
			},
		},
	},
}
