-- vim.lsp.buf.references(nil, {on_list = function(opts) vim.print(opts) end})
-- TODO: perfect enhancement I can make to my multibuffer
-- but I actually need to make it better
-- probably a centered float that displays one at a time
-- but I can tab through it?
-- easier to handle refreshing if I did it that way too!
local M = {}

--- @return table<multibuffer.Entry>
M.diagnostic_entries = function()
	local diagnostics = vim.diagnostic.get(nil, { severity = "ERROR" })
	local entries = {}
	for i, diagnostic in ipairs(diagnostics) do
		if diagnostic.bufnr then
			local name = vim.api.nvim_buf_get_name(diagnostic.bufnr)
			local path = vim.fn.fnamemodify(name, ":~:.")
			table.insert(entries, {
				index = i,
				bufnr = diagnostic.bufnr,
				lnum = diagnostic.lnum,
				col = diagnostic.col,
				msg = diagnostic.message,
				fp = path,
			})
		end
	end
	return entries
end

return M
