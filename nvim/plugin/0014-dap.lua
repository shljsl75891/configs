vim.pack.add({
	"https://github.com/igorlfs/nvim-dap-view",
	"https://codeberg.org/mfussenegger/nvim-dap.git",
})

require("dap-view").setup({
	virtual_text = {
		enabled = true,
		format = function(variable, _, _)
			local value = variable.value
			if #value > 100 then
				return " " .. value:sub(1, 75) .. "..."
			end
			return " " .. value:gsub("%s+", " ")
		end,
	},
	winbar = {
		sections = {
			"scopes",
			"console",
			"watches",
			"repl",
			"breakpoints",
			"threads",
			"sessions",
		},
		default_section = "console",
		show_keymap_hints = false,
		base_sections = {
			sessions = {
				keymap = "D",
				label = "DAP Sessions",
			},
		},
		controls = {
			enabled = true,
			position = "right",
			buttons = {
				"play",
				"step_over",
				"step_into",
				"step_out",
				"step_back",
				"run_last",
				"terminate",
				"disconnect",
			},
		},
	},
	windows = {
		size = 0.4,
		position = "right",
		terminal = {
			size = 0.4,
			position = "below",
		},
	},
	auto_toggle = true,
})

local dap = require("dap")

dap.adapters["pwa-node"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		command = "node",
		args = {
			vim.fn.stdpath("data")
				.. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
			"${port}",
		},
	},
	options = {
		max_retries = 3,
		disconnect_timeout_sec = 5,
	},
}

local node_configs = {
	{
		type = "pwa-node",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		sourceMaps = true,
		skipFiles = { "<node_internals>/**" },
	},
	{
		type = "pwa-node",
		request = "attach",
		name = "Attach to process",
		processId = require("dap.utils").pick_process,
		cwd = "${workspaceFolder}",
		console = "integratedTerminal",
		skipFiles = { "<node_internals>/**" },
	},
	{
		type = "pwa-node",
		request = "launch",
		name = "Launch using npm",
		cwd = "${workspaceFolder}",
		runtimeExecutable = "npm",
		runtimeArgs = { "run-script", "start" },
		console = "integratedTerminal",
		skipFiles = { "<node_internals>/**" },
	},
	{
		type = "pwa-node",
		request = "launch",
		name = "Launch using npm in dev mode",
		cwd = "${workspaceFolder}",
		runtimeExecutable = "npm",
		runtimeArgs = { "run-script", "dev" },
		console = "integratedTerminal",
		skipFiles = { "<node_internals>/**" },
	},
}

dap.configurations.javascript = node_configs
dap.configurations.typescript = node_configs
dap.configurations.javascriptreact = node_configs
dap.configurations.typescriptreact = node_configs

-- Keymaps
local opts = { noremap = true, silent = true }

opts.desc = "[T]oggle [B]reakpoint"
vim.keymap.set("n", "<leader>tb", function()
	require("dap").toggle_breakpoint()
end, opts)

opts.desc = "[T]oggle conditional [B]reakpoint"
vim.keymap.set("n", "<leader>tB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, opts)

opts.desc = "Run/Continue"
vim.keymap.set("n", "<F5>", function()
	require("dap").continue({ new = true })
end, opts)

opts.desc = "Run/Continue"
vim.keymap.set("n", "<F1>", function()
	require("dap").continue()
end, opts)

opts.desc = "Step Over"
vim.keymap.set("n", "<F2>", function()
	require("dap").step_over()
end, opts)

opts.desc = "Step Into"
vim.keymap.set("n", "<F3>", function()
	require("dap").step_into()
end, opts)

opts.desc = "Step Out"
vim.keymap.set("n", "<F4>", function()
	require("dap").step_out()
end, opts)

opts.desc = "Terminate"
vim.keymap.set("n", "<F9>", function()
	require("dap").terminate()
end, opts)

opts.desc = "Hover variable"
vim.keymap.set("n", "<leader>k", function()
	require("dap.ui.widgets").hover()
end, opts)

opts.desc = "Toggle [D]ap [V]iew"
vim.keymap.set("n", "<leader>dv", function()
	require("dap-view").toggle()
end, opts)

opts.desc = "Add Expression to Watches"
vim.keymap.set("n", "<leader>?", function()
	require("dap-view").add_expr()
end, opts)
