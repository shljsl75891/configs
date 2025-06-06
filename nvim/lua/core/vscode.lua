local vscode = require("vscode")
local opts = { noremap = true, silent = true }

opts.desc = "Trigger parameter hints"
vim.keymap.set("i", "<C-h>", function()
	vscode.action("editor.action.triggerParameterHints")
end, opts)

opts.desc = "Previous editor tab"
vim.keymap.set("n", "<S-h>", function()
	vscode.action("workbench.action.previousEditor")
end, opts)

opts.desc = "Next editor tab"
vim.keymap.set("n", "<S-l>", function()
	vscode.action("workbench.action.nextEditor")
end, opts)

-- === LSP Actions ===
opts.desc = "Go to type definition"
vim.keymap.set("n", "gT", function()
	vscode.action("editor.action.goToTypeDefinition")
end, opts)

opts.desc = "Go to definition"
vim.keymap.set("n", "gd", function()
	vscode.action("editor.action.revealDefinition")
end, opts)

opts.desc = "Find references"
vim.keymap.set("n", "<leader>rr", function()
	vscode.action("editor.action.goToReferences")
end, opts)

opts.desc = "Rename symbol"
vim.keymap.set("n", "<leader>rn", function()
	vscode.action("editor.action.rename")
end, opts)

opts.desc = "Code action / Quick fix"
vim.keymap.set("n", "<leader>ca", function()
	vscode.action("editor.action.quickFix")
end, opts)

opts.desc = "Show hover (definition preview)"
vim.keymap.set("n", "K", function()
	vscode.action("editor.action.showDefinitionPreviewHover")
end, opts)

opts.desc = "Toggle breakpoint"
vim.keymap.set("n", "<leader>tb", function()
	vscode.action("editor.debug.action.toggleBreakpoint")
end, opts)

-- === Diagnostics Navigation ===
opts.desc = "Previous diagnostic"
vim.keymap.set("n", "[d", function()
	vscode.action("editor.action.marker.prev")
end, opts)

opts.desc = "Next diagnostic"
vim.keymap.set("n", "]d", function()
	vscode.action("editor.action.marker.next")
end, opts)

opts.desc = "Close Other tabs"
vim.keymap.set("n", "<leader>co", function()
	vscode.action("workbench.action.closeOtherEditors")
end, opts)
