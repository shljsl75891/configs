return {
	"samir-roy/code-bridge.nvim",
	opts = {
		tmux = {
			target_mode = "window_name",
			process_name = "opencode",
			window_name = "opencode",
			switch_to_target = true,
			find_node_process = false,
		},
		chat = {
			model = "zai-coding-plan/glm-5-turbo",
		},
	},
	keys = {
		{
			"<leader>ic",
			":CodeBridgeTmux<CR>",
			mode = { "n", "v" },
			silent = true,
			desc = "[I]nterative [C]chat with context",
		},
		{
			"<leader>ir",
			":CodeBridgeResumePrompt<CR>",
			mode = { "n", "v" },
			silent = true,
			desc = "[I]nterative [R]esume chat",
		},
		{
			"<leader>ip",
			":CodeBridgeTmuxInteractive<CR>",
			mode = { "n", "v" },
			silent = true,
			desc = "[I]nteractive [P]rompt (custom prompt with context)",
		},
		{
			"<leader>gd",
			"<cmd>CodeBridgeTmuxDiff<CR>",
			desc = "[G]it [D]iff to claude",
			silent = true,
		},
		{
			"<leader>gD",
			"<cmd>CodeBridgeTmuxDiffStaged<CR>",
			desc = "[G]it [D]iff staged to claude",
			silent = true,
		},
		-- Diagnostics
		{
			"<leader>cd",
			":CodeBridgeTmuxDiagnostics<CR>",
			desc = "Send [C]urrent Buffer [D]iagnostics Errors",
			silent = true,
		},
		{
			"<leader>ce",
			":CodeBridgeTmuxDiagnosticsErrors<CR>",
			desc = "Send [A]ll [D]iagnostics Errors",
			silent = true,
		},
		-- Chat buffer interaction
		{
			"<leader>tc",
			":CodeBridgeChat<CR>",
			mode = { "n" },
			silent = true,
			desc = "[T]emporary [C]chat",
		},
		{
			"<leader>tq",
			":CodeBridgeQuery<CR>",
			mode = { "n", "v" },
			silent = true,
			desc = "[T]emporary [Q]uery with context",
		},
		{
			"<leader>ht",
			":CodeBridgeHide<CR>",
			mode = { "n" },
			silent = true,
			desc = "[H]ide [T]emporary Chat Buffer",
		},
		{
			"<leader>st",
			":CodeBridgeShow<CR>",
			mode = { "n" },
			silent = true,
			desc = "[S]how [T]emporary Chat Buffer",
		},
		{
			"<leader>cq",
			":CodeBridgeCancelQuery<CR>",
			mode = { "n" },
			silent = true,
			desc = "[C]ancel [Q]uery",
		},
	},
}
