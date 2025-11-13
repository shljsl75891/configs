return {
	"samir-roy/code-bridge.nvim",
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
			desc = "[I]nterative [C]chat with context",
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
		-- Chat interface
		{
			"<leader>tq",
			":CodeBridgeQuery<CR>",
			mode = { "n", "v" },
			desc = "[T]emporary [Q]uery (with selection or current file)",
		},
		{ "<leader>tc", "<cmd>CodeBridgeChat<CR>", desc = "[T]emporary [C]hat" },
		{
			"<leader>cc",
			"<cmd>CodeBridgeWipe<CR>",
			desc = "[C]lear [C]hat",
		},
	},
	opts = {
		tmux = {
			target_mode = "window_name",
			window_name = "agent",
			switch_to_target = true,
			find_node_process = false,
		},
		interactive = { use_telescope = false },
	},
}
