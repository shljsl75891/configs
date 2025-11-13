return {
	"igorlfs/nvim-dap-view",
	dependencies = {
		"https://codeberg.org/mfussenegger/nvim-dap.git",
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {
				enabled = true,
				commented = true,
				enabled_commands = false,
				highlight_changed_variables = false,
				highlight_new_as_changed = false,
				show_stop_reason = true,
				clear_on_continue = true,
				only_first_definition = true,
				all_references = false,
				display_callback = function(variable)
					local value = variable.value
					if #value > 100 then
						return value:sub(1, 75) .. "..."
					end
					return value
				end,
			},
		},
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
			desc = "[T]oggle conditional [B]reakpoint",
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
			desc = "Step Into",
		},
		{
			"<F3>",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
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
			desc = "Hover variable",
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
	end,
}
