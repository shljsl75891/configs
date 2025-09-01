return {
	"rcarriga/nvim-dap-ui",
	dependencies = {
		"https://codeberg.org/mfussenegger/nvim-dap.git",
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {
				enabled = true,
				highlight_changed_variables = true,
				show_stop_reason = true,
				virt_text_pos = "inline",
			},
		},
		"nvim-neotest/nvim-nio",
	},
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
			"<leader>?",
			function()
				require("dapui").eval(nil, { enter = true })
			end,
			desc = "Evaluate Expression",
		},
	},
	config = function()
		require("dapui").setup()

		-- automatically opesn and close dapui when debugging
		local dap, dapui = require("dap"), require("dapui")
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

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
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach to process",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch using npm",
				cwd = "${workspaceFolder}",
				runtimeExecutable = "npm",
				runtimeArgs = { "run-script", "start" },
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch using npm in dev mode",
				cwd = "${workspaceFolder}",
				runtimeExecutable = "npm",
				runtimeArgs = { "run-script", "dev" },
			},
		}

		dap.configurations.typescript = dap.configurations.javascript
	end,
}
