local M = {}

local qfx = require("multibuffer.sources.quickfix")

--- @param on_load fun(entries: table<multibuffer.Entry>)
M.search = function(on_load)
	-- TODO: improve the ui to allow file pattern filtering too!
	vim.ui.input({}, function(input)
		if not input or #input == 0 then
			on_load({})
			return
		end

		vim.cmd(string.format("vimgrep /%s/j ./**", input))
		local entries = qfx.quickfix_entries()
		on_load(entries)
	end)
end

return M
