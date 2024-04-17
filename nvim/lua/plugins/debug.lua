return {
	"rcarriga/nvim-dap-ui",
	keys = { "<leader>tb" },
	dependencies = {
		"mfussenegger/nvim-dap",
		"mxsdev/nvim-dap-vscode-js",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local dapwidgets = require("dap.ui.widgets")

		-- Setting up dap ui
		dapui.setup({})

		-- Adding event listeners for dap ui from dap
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

		require("dap-vscode-js").setup({
			-- Path to vscode-js-debug installation.
			debugger_path = "/home/sahil.jassal/gitprojects/vscode-js-debug",
		})

		local languages = { "typescript", "javascript" }

		for _, language in ipairs(languages) do
			require("dap").configurations[language] = {
				-- Node.js
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
					sourceMaps = true,
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}
		end

		-- Keymaps for easier basic debugging
		vim.keymap.set("n", "<leader>tb", dap.toggle_breakpoint)
		vim.keymap.set("n", "<F5>", dap.continue)
		vim.keymap.set("n", "<F10>", dap.step_over)
		vim.keymap.set("n", "<F11>", dap.step_into)
		vim.keymap.set("n", "<F12>", dap.step_out)
		vim.keymap.set({ "n", "v" }, "<leader>dh", dapwidgets.hover)
		vim.keymap.set({ "n", "v" }, "<leader>dp", dapwidgets.preview)
	end,
}
