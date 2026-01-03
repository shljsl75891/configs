return {
	"samir-roy/code-bridge.nvim",
	opts = {
		tmux = {
			target_mode = "window_name",
			window_name = "agent",
			switch_to_target = true,
			find_node_process = false,
		},
		interactive = { use_telescope = false },
	},
	keys = {
		{
			"<leader>ic",
			":CodeBridgeTmux<CR>",
			mode = { "n", "v" },
			desc = "[I]nterative [C]chat with context",
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
		-- Diagnostics
		{
			"<leader>cd",
			":CodeBridgeTmuxDiagnosticsErrors<CR>",
			desc = "Send [C]urrent Buffer [D]iagnostics Errors",
		},
		{
			"<leader>ad",
			":CodeBridgeTmuxDiagnosticsErrors<CR>",
			desc = "Send [A]ll [D]iagnostics Errors",
		},
	},
}
