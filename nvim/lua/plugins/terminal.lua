return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		shell = "powershell.exe -nologo",
		direction = "float",
		float_opts = {
			border = "solid",
		},
		highlights = {
			NormalFloat = {
				link = "NormalFloat",
			},
			FloatBorder = {
				link = "NormalFloat",
			},
		},
		open_mapping = "<C-\\>",
		start_in_insert = true,
		insert_mappings = true,
		terminal_mappings = true,
	},
}
