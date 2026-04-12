vim.pack.add({ "https://github.com/samir-roy/code-bridge.nvim" })

require("code-bridge").setup({
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
})

local opts = { noremap = true, silent = true }

opts.desc = "[I]nterative [C]chat with context"
vim.keymap.set({ "n", "v" }, "<leader>ic", ":CodeBridgeTmux<CR>", opts)

opts.desc = "[I]nterative [R]esume chat"
vim.keymap.set({ "n", "v" }, "<leader>ir", ":CodeBridgeResumePrompt<CR>", opts)

opts.desc = "[I]nteractive [P]rompt (custom prompt with context)"
vim.keymap.set(
	{ "n", "v" },
	"<leader>ip",
	":CodeBridgeTmuxInteractive<CR>",
	opts
)

opts.desc = "[G]it [D]iff to claude"
vim.keymap.set("n", "<leader>gd", "<cmd>CodeBridgeTmuxDiff<CR>", opts)

opts.desc = "[G]it [D]iff staged to claude"
vim.keymap.set("n", "<leader>gD", "<cmd>CodeBridgeTmuxDiffStaged<CR>", opts)

opts.desc = "Send [C]urrent Buffer [D]iagnostics Errors"
vim.keymap.set("n", "<leader>cd", ":CodeBridgeTmuxDiagnostics<CR>", opts)

opts.desc = "Send [A]ll [D]iagnostics Errors"
vim.keymap.set("n", "<leader>ce", ":CodeBridgeTmuxDiagnosticsErrors<CR>", opts)

opts.desc = "[T]emporary [C]chat"
vim.keymap.set("n", "<leader>tc", ":CodeBridgeChat<CR>", opts)

opts.desc = "[T]emporary [Q]uery with context"
vim.keymap.set({ "n", "v" }, "<leader>tq", ":CodeBridgeQuery<CR>", opts)

opts.desc = "[H]ide [T]emporary Chat Buffer"
vim.keymap.set("n", "<leader>hc", ":CodeBridgeHide<CR>", opts)

opts.desc = "[S]how [T]emporary Chat Buffer"
vim.keymap.set("n", "<leader>sc", ":CodeBridgeShow<CR>", opts)

opts.desc = "[C]ancel [Q]uery"
vim.keymap.set("n", "<leader>cq", ":CodeBridgeCancelQuery<CR>", opts)
