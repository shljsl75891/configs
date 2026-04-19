-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank({ timeout = 80 })
	end,
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	pattern = "*",
})

-- For Angular treesitter
vim.filetype.add({
	pattern = {
		-- Sets the filetype to `htmlangular` if it matches the pattern
		[".*%.component%.html"] = "htmlangular",
	},
})

-- Rename files using LSP operations with snacks plugin
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "netrw" },
	group = vim.api.nvim_create_augroup("NetrwOnRename", { clear = true }),
	callback = function()
		vim.keymap.set("n", "R", function()
			local original_file_path = vim.b.netrw_curdir
				.. "/"
				.. vim.fn["netrw#Call"]("NetrwGetWord")

			vim.ui.input(
				{ prompt = "Move/rename to:", default = original_file_path },
				function(target_file_path)
					if target_file_path and target_file_path ~= "" then
						local file_exists = vim.uv.fs_access(target_file_path, "W")

						if not file_exists then
							vim.uv.fs_rename(original_file_path, target_file_path)

							require("snacks").rename.on_rename_file(
								original_file_path,
								target_file_path
							)
						else
							vim.notify(
								"File '" .. target_file_path .. "' already exists! Skipping...",
								vim.log.levels.ERROR
							)
						end

						-- Refresh netrw
						vim.cmd(":Ex " .. vim.b.netrw_curdir)
					end
				end
			)
		end, { remap = true, buffer = true })
	end,
})
