local M = {}

--- @param t table
--- @param comparator fun(a: any,b: any):boolean
local group_by = function(t, comparator)
	local grouped = {}
	local group = {}
	for _, v in ipairs(t) do
		if #group > 0 and comparator(group[1], v) then -- if you belong in the current group
			table.insert(group, v)
		elseif #group > 0 then -- if you don't belong in the current group
			table.insert(grouped, group) -- insert the previous group
			group = { v } -- create a new group
		else -- for when we have an empty group (only run once)
			table.insert(group, v)
		end
	end
	if #group > 0 then
		table.insert(grouped, group)
	end

	return grouped
end

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
	local diagnostics = vim.diagnostic.get(nil)
	local diagnostic_groups = group_by(diagnostics, function(a, b)
		-- TODO: can pull this up into a config option
		return math.abs(a.lnum - b.lnum) < 2
	end)

	local entries = {}
	local i = 1
	for _, group in ipairs(diagnostic_groups) do
		local diagnostic = group[1]
		if diagnostic and diagnostic.bufnr then
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
			i = i + 1
		end
	end

	return entries
end

return M
