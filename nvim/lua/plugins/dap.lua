return {
	{
		"igorlfs/nvim-dap-view",
		dependencies = {
			{ url = "https://codeberg.org/mfussenegger/nvim-dap.git" },
		},
		cmd = { "DapContinue", "DapToggleBreakpoint", "DapTerminate" },
		init = function()
			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "●", texthl = "DiagnosticError" }
			)
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "●", texthl = "DiagnosticWarn" }
			)
			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = "●", texthl = "DiagnosticHint" }
			)
			vim.fn.sign_define(
				"DapLogPoint",
				{ text = "◉", texthl = "DiagnosticInfo" }
			)
			vim.fn.sign_define("DapStopped", {
				text = "→",
				texthl = "DiagnosticOk",
				linehl = "debugPC",
				numhl = "",
			})
		end,
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
						"watches",
						"repl",
						"breakpoints",
						"threads",
						"sessions",
					},
					default_section = "scopes",
					show_keymap_hints = false,
					base_sections = {
						sessions = {
							keymap = "D",
							label = "DAP Sessions",
						},
					},
					controls = { enabled = false },
				},
				windows = {
					size = 0.3,
					position = "right",
					terminal = {
						size = 0.4,
						position = "below",
					},
				},
				auto_toggle = false,
			})

			local dap = require("dap")

			-- Auto-open view on session start, but never auto-close on terminate/fail
			-- Skip open() if terminal is already visible to prevent restart creating extra splits
			for _, event in ipairs({ "launch", "attach" }) do
				dap.listeners.before[event]["dap-view-open"] = function()
					local wins = vim.api.nvim_tabpage_list_wins(0)
					local has_term = vim.iter(wins):find(function(w)
						return vim.w[w].dapview_win_term
					end)
					if not has_term then
						require("dap-view").open()
					end
				end
			end

			-- Focus Ghostty + correct tmux pane when debugger hits a breakpoint
			dap.listeners.after.event_stopped["focus-ghostty"] = function()
				vim.fn.jobstart({
					"osascript",
					"-e",
					'tell application "Ghostty" to activate',
				})
				local pane = vim.env.TMUX_PANE
				if pane then
					vim.fn.jobstart({ "tmux", "select-pane", "-t", pane })
					vim.fn.jobstart({ "tmux", "switch-client", "-t", pane })
				end
			end

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
