return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		"tpope/vim-dadbod",
		"tpope/vim-dotenv",
		{
			"kristijanhusak/vim-dadbod-completion",
			ft = { "sql", "mysql", "plsql" },
		},
	},
	cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_winwidth = 64
		vim.g.db_ui_win_position = "right"
		vim.g.db_ui_execute_on_save = 0
		vim.g.db_ui_disable_info_notifications = 1
		vim.g.db_ui_disable_progress_bar = 1
	end,
}
