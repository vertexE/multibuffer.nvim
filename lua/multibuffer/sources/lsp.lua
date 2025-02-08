local M = {}

--- @param on_load fun(entries: table<multibuffer.Entry>)
M.symbol_references_entries = function(on_load)
	vim.lsp.buf.references(nil, {
		on_list = function(result)
			local entries = {}
			local references = result.items
			for i, reference in ipairs(references) do
				local bufnr = vim.fn.bufadd(reference.filename)
				local path = vim.fn.fnamemodify(reference.filename, ":~:.")
				table.insert(entries, {
					index = i,
					bufnr = bufnr,
					lnum = reference.lnum - 1,
					col = reference.col,
					msg = reference.text,
					fp = path,
				})
			end
			on_load(entries)
		end,
	})
end

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
