return {
	{
		"samir-roy/code-bridge.nvim",
		cmd = {
			"CodeBridgeTmux",
			"CodeBridgeResumePrompt",
			"CodeBridgeTmuxInteractive",
			"CodeBridgeTmuxDiff",
			"CodeBridgeTmuxDiffStaged",
			"CodeBridgeTmuxDiagnostics",
			"CodeBridgeTmuxDiagnosticsErrors",
			"CodeBridgeChat",
			"CodeBridgeQuery",
			"CodeBridgeHide",
			"CodeBridgeShow",
			"CodeBridgeCancelQuery",
		},
		keys = {
			{
				"<leader>ic",
				":CodeBridgeTmux<CR>",
				mode = { "n", "v" },
				desc = "[I]nterative [C]hat with context",
			},
			{
				"<leader>ir",
				":CodeBridgeResumePrompt<CR>",
				mode = { "n", "v" },
				desc = "[I]nterative [R]esume chat",
			},
			{
				"<leader>ip",
				":CodeBridgeTmuxInteractive<CR>",
				mode = { "n", "v" },
				desc = "[I]nteractive [P]rompt (custom prompt with context)",
			},
			{
				"<leader>gd",
				"<cmd>CodeBridgeTmuxDiff<CR>",
				desc = "[G]it [D]iff to claude",
			},
			{
				"<leader>gD",
				"<cmd>CodeBridgeTmuxDiffStaged<CR>",
				desc = "[G]it [D]iff staged to claude",
			},
			{
				"<leader>cd",
				":CodeBridgeTmuxDiagnostics<CR>",
				desc = "Send [C]urrent Buffer [D]iagnostics Errors",
			},
			{
				"<leader>ce",
				":CodeBridgeTmuxDiagnosticsErrors<CR>",
				desc = "Send [A]ll [D]iagnostics Errors",
			},
			{ "<leader>tc", ":CodeBridgeChat<CR>", desc = "[T]emporary [C]hat" },
			{
				"<leader>tq",
				":CodeBridgeQuery<CR>",
				mode = { "n", "v" },
				desc = "[T]emporary [Q]uery with context",
			},
			{
				"<leader>hc",
				":CodeBridgeHide<CR>",
				desc = "[H]ide [T]emporary Chat Buffer",
			},
			{
				"<leader>sc",
				":CodeBridgeShow<CR>",
				desc = "[S]how [T]emporary Chat Buffer",
			},
			{ "<leader>cq", ":CodeBridgeCancelQuery<CR>", desc = "[C]ancel [Q]uery" },
		},
		opts = {
			tmux = {
				target_mode = "window_name",
				process_name = "opencode",
				window_name = "opencode",
				switch_to_target = true,
				find_node_process = false,
			},
			chat = {
				model = "github-copilot/claude-haiku-4.5",
			},
		},
	},
}
