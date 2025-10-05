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
		function(err, result, ctx, config)
			-- {
			--     originSelectionRange = {
			--       ["end"] = {
			--         character = 26,
			--         line = 103
			--       },
			--       start = {
			--         character = 2,
			--         line = 103
			--       }
			--     },
			--     targetRange = {
			--       ["end"] = {
			--         character = 3,
			--         line = 101
			--       },
			--       start = {
			--         character = 29,
			--         line = 90
			--       }
			--     },
			--     targetSelectionRange = {
			--       ["end"] = {
			--         character = 3,
			--         line = 101
			--       },
			--       start = {
			--         character = 29,
			--         line = 90
			--       }
			--     },
			--     targetUri = "file:///Users/jfdenton/work/multibuffer.nvim/lua/multibuffer/sources/lsp.lua"
			--   }
			local entries = {}
			local fp_to_buf = {}
			for i, symbol in ipairs(result) do
				local bufnr = -1
				if fp_to_buf[symbol.targetUri] then
					bufnr = fp_to_buf[symbol.targetUri]
				else
					bufnr = vim.api.nvim_create_buf(true, false)
					fp_to_buf[symbol.targetUri] = bufnr
				end

				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd(string.format("edit %s", symbol.targetUri))
				end)
				local path = vim.fn.fnamemodify(symbol.targetUri, ":~:.")
				local line = symbol.targetRange.start.line
				local preview = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
				table.insert(entries, {
					index = i,
					bufnr = bufnr,
					lnum = line,
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
