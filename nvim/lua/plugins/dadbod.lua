return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{
			"kristijanhusak/vim-dadbod-completion",
			ft = { "sql", "mysql", "plsql" },
			lazy = true,
		},
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		local db_names_str = os.getenv("DB_NAMES") or ""
		local db_password = os.getenv("DB_PASSWORD") or "postgres"
		local db_names = {}

		for name in db_names_str:gmatch("([^,]+)") do
			table.insert(db_names, name)
		end
		local databases = {}
		for _, name in ipairs(db_names) do
			table.insert(databases, {
				name = name,
				url = "postgres://postgres:"
					.. db_password
					.. "@localhost:5432/"
					.. name,
			})
		end

		vim.g.dbs = databases
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_winwidth = 64
		vim.g.db_ui_win_position = "right"
		vim.g.db_ui_execute_on_save = 0
		vim.g.db_ui_disable_info_notifications = 1
		vim.g.db_ui_disable_progress_bar = 1
	end,
}
