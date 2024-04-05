return {
	"codota/tabnine-nvim",
	event = "InsertEnter",
	build = "./dl_binaries.sh",
	config = function()
		require("tabnine").setup({
			disable_auto_comment = false,
			accept_keymap = "<C-y>",
			dismiss_keymap = "<C-e>",
			debounce_ms = 250,
			codelens_enabled = false,
			exclude_filetypes = { "TelescopePrompt" },
			log_file_path = nil, -- absolute path to Tabnine log file
		})
	end,
}
