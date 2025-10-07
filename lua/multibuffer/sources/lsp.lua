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

local client_encoding = function(method)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if client:supports_method(method) then
			return client.offset_encoding or "utf-16"
		end
	end

	return "utf-16"
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

--- @param bufnr integer|nil
--- @return table<multibuffer.Entry>
M.diagnostic_entries = function(bufnr)
	local diagnostics = vim.diagnostic.get(bufnr)
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
				severity = diagnostic.severity,
				col = diagnostic.col,
				msg = diagnostic.message,
				fp = path,
			})
			i = i + 1
		end
	end

	return entries
end

--- @param on_load fun(entries: table<multibuffer.Entry>)
M.symbol_definiton_entries = function(on_load)
	vim.lsp.buf_request(
		0,
		"textDocument/definition",
		vim.lsp.util.make_position_params(nil, client_encoding("textDocument/definition")),
		function(_, result, _, _)
			if not result then
				on_load({})
			end
			local entries = {}
			for i, symbol in ipairs(result) do
				local bufnr = vim.uri_to_bufnr(symbol.targetUri)
				vim.fn.bufload(bufnr)
				local preview = vim.api.nvim_buf_get_lines(
					bufnr,
					symbol.targetRange.start.line,
					symbol.targetRange.start.line + 1,
					false
				)[1] or ""
				local path = symbol.targetUri:gsub("^file://", "", 1)
				table.insert(entries, {
					index = i,
					bufnr = bufnr,
					lnum = symbol.targetRange.start.line,
					col = symbol.targetRange.start.character,
					msg = preview,
					fp = path,
				})
			end
			on_load(entries)
		end
	)
end

return M
