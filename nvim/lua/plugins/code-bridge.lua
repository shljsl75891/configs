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
			model = "github-copilot/gpt-4.1",
		},
	},
	cmd = { "CodeBridgeChat", "CodeBridgeQuery" },
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
	},
}
