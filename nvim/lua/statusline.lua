-- Mode names and highlight groups
function _G.mode_label()
	local map = {
		n = { "NORMAL", "MiniStatuslineModeNormal" },
		i = { "INSERT", "MiniStatuslineModeInsert" },
		v = { "VISUAL", "MiniStatuslineModeVisual" },
		V = { "V-LINE", "MiniStatuslineModeVisual" },
		["\22"] = { "V-BLOCK", "MiniStatuslineModeVisual" },
		s = { "SELECT", "MiniStatuslineModeOther" },
		S = { "S-LINE", "MiniStatuslineModeOther" },
		R = { "REPLACE", "MiniStatuslineModeReplace" },
		c = { "COMMAND", "MiniStatuslineModeCommand" },
		t = { "TERMINAL", "MiniStatuslineModeOther" },
		o = { "O-PEND", "MiniStatuslineModeOther" },
	}
	local m = vim.api.nvim_get_mode().mode
	local entry = map[m] or { m:upper(), "MiniStatuslineModeOther" }
	return string.format("%%#%s# %s %%#StatusLine#", entry[2], entry[1])
end

-- global single status line
vim.opt.laststatus = 3
vim.opt.statusline = "%{%v:lua._G.mode_label()%}%=%#MiniStatuslineDevinfo# %{FugitiveStatusline()} %#StatusLine# %y"
-- winbar: path + modified + diagnostics + flags (all with same bg)
vim.opt.winbar = "%#GruvboxYellowBold# %f %m %{%v:lua.vim.diagnostic.status()%} %r"
-- mode is shown in statusline already
vim.opt.showmode = false
