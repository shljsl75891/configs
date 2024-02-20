return {
	"codota/tabnine-nvim",
	build = "./dl_binaries.sh",
	config = function()
		require("tabnine").setup({
			disable_auto_comment = true,
			accept_keymap = "]",
			dismiss_keymap = "[",
			debounce_ms = 200,
			codelens_enabled = false,
			suggestion_color = { gui = "#928374", cterm = 256 },
			codelens_color = { gui = "#928374", cterm = 256 },
			exclude_filetypes = { "TelescopePrompt", "NvimTree" },
			log_file_path = nil, -- absolute path to Tabnine log file
		})
	end,
}
