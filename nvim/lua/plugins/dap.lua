return {
	{
		"igorlfs/nvim-dap-view",
		dependencies = {
			{ url = "https://codeberg.org/mfussenegger/nvim-dap.git" },
		},
		cmd = { "DapContinue", "DapToggleBreakpoint", "DapTerminate" },
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
					require("dap").continue({ new = true })
				end,
				desc = "Run/Continue (new session)",
			},
			{
				"<F1>",
				function()
					require("dap").continue()
				end,
				desc = "Run/Continue",
			},
			{
				"<F2>",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<F3>",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<F4>",
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
				enrich_config = function(config, on_config)
					local c = vim.deepcopy(config)
					-- js-debug requires type="pwa-node"; remap "node" from launch.json
					c.type = "pwa-node"
					c.console = c.console or "integratedTerminal"
					on_config(c)
				end,
			}

			-- Alias "node" → pwa-node adapter so launch.json with type:"node" works
			dap.adapters["node"] = dap.adapters["pwa-node"]

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
	},
}
