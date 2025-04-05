-- A function to move selected lines down in visual mode
function Move_lines_down_visual()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local last_line = vim.api.nvim_buf_line_count(0)

	local selected_lines_count = vim.fn.line("'>") - vim.fn.line("'<")

	if current_line + selected_lines_count < last_line then
		vim.api.nvim_command("'<, '>m '>+1")
		vim.api.nvim_command("normal! gv=gv")
	-- When we hit the bottom we just reselect the lines
	else
		vim.api.nvim_command("normal! gv")
	end
end

-- A function to move selected lines up in visual mode
function Move_lines_up_visual()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]

	if current_line > 1 then
		vim.api.nvim_command("'<, '>m '<-2")
		vim.api.nvim_command("normal! gv=gv")
	-- When we hit the top we just reselect the lines
	else
		vim.api.nvim_command("normal! gv")
	end
end

-- Highlight on yank
local highlight_group =
	vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			timeout = 60,
		})
	end,
	group = highlight_group,
	pattern = "*",
})

-- For Angular treesitter
vim.filetype.add({
	pattern = {
		-- Sets the filetype to `htmlangular` if it matches the pattern
		[".*%.component%.html"] = "htmlangular",
	},
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = vim.api.nvim_create_augroup("TrailingWhitespace", { clear = true }),
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
