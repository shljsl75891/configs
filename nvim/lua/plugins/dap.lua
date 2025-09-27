return {
	"igorlfs/nvim-dap-view",
	dependencies = { "https://codeberg.org/mfussenegger/nvim-dap.git" },
	keys = {
		{
			"<leader>tb",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "[T]oggle [B]reakpoint",
		},
		{
			"<leader>tB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "[T]oggle [B]reakpoint with condition",
		},
		{
			"<F5>",
			function()
				require("dap").continue()
			end,
			desc = "Run/Continue",
		},
		{
			"<F1>",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<F2>",
			function()
				require("dap").step_into()
			end,
			desc = "Step Out",
		},
		{
			"<F3>",
			function()
				require("dap").step_out()
			end,
			desc = "Step Into",
		},
		{
			"<F9>",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate",
		},
		{
			"<leader>k",
			function()
				require("dap.ui.widgets").hover()
			end,
			desc = "Terminate",
		},
		{
			"<leader>dv",
			function()
				require("dap-view").toggle()
			end,
			desc = "Toggle [D]ap [V]iew",
		},
		{
			"<leader>?",
			function()
				require("dap-view").add_expr()
			end,
			desc = "Add Expression to Watches",
		},
	},
	config = function()
		require("dap-view").setup({
			winbar = {
				sections = {
					"scopes",
					"repl",
					"watches",
					"breakpoints",
					"threads",
					"sessions",
				},
				default_section = "scopes",
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
				height = 0.25,
				position = "below",
				terminal = {
					width = 0.5,
					position = "right",
					start_hidden = false,
				},
			},
			auto_toggle = true,
		})

		-- automatically opesn and close dapui when debugging
		local dap = require("dap")

		-- Adapter configuration (How DAP client should start the debugger)
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
		}

		-- Debugger configuration (How debugger should connect with debugee)
		dap.configurations.javascript = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
				console = "integratedTerminal",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach to process",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
				console = "integratedTerminal",
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch using npm",
				cwd = "${workspaceFolder}",
				runtimeExecutable = "npm",
				runtimeArgs = { "run-script", "start" },
				console = "integratedTerminal",
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch using npm in dev mode",
				cwd = "${workspaceFolder}",
				runtimeExecutable = "npm",
				runtimeArgs = { "run-script", "dev" },
				console = "integratedTerminal",
			},
		}

		dap.configurations.typescript = dap.configurations.javascript
	end,
}
