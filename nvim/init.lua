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


-- Options must load before lazy so leader is set when keys= specs are processed
require("core.options")
require("core.lazy")
require("core.statusline")
require("core.keymaps")
require("core.autocmds")

-- packadd after lazy so its lua/ dir is found when vim.loader rescans rtp
vim.cmd.packadd("nvim.difftool")
vim.cmd.packadd("nvim.undotree")
