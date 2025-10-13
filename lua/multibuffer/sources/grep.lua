local M = {}

local qfx = require("multibuffer.sources.quickfix")

local previous_entry_filepaths = {}

--- @param on_load fun(entries: table<multibuffer.Entry>)
--- @param use_previous ?boolean
M.search = function(on_load, use_previous)
	vim.ui.input({}, function(input)
		if not input or #input == 0 then
			on_load({})
			return
		end

		if use_previous and #previous_entry_filepaths > 0 then
			vim.cmd(string.format("vimgrep /%s/j %s", input, table.concat(previous_entry_filepaths, " ")))
		else
			vim.cmd(string.format("vimgrep /%s/j ./**", input))
		end
		local entries = qfx.quickfix_entries()
		previous_entry_filepaths = vim.iter(entries)
			:map(function(entry)
				return entry.fp
			end)
			:totable()
		on_load(entries)
	end)
end

return M
