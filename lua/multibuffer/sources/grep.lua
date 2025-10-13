local M = {}

local prev_search_results = {}

local keys = function(set)
	local _keys = {}
	for k, _ in pairs(set) do
		table.insert(_keys, k)
	end
	return _keys
end

---comment
---@param i integer
---@param line string
---@return multibuffer.Entry
local parse_rg_line = function(i, line)
	local segments = vim.split(line, ":")
	-- local msg = table.concat(segments, ":", 4)
	local path = segments[1]
	path = path:gsub("^%./", "")
	path = vim.fn.fnamemodify(path, ":p")
	local lnum = segments[2] and (tonumber(segments[2]) - 1) or nil
	local col = segments[3] and (tonumber(segments[3]) - 1) or nil
	return { index = i, bufnr = -1, fp = path, lnum = lnum, col = col, lazy = true }
end

--- @param on_load fun(entries: table<multibuffer.Entry>)
--- @param use_previous ?boolean
M.search = function(on_load, use_previous)
	vim.ui.input({ prompt = use_previous and "grep+" or "grep" }, function(input)
		if not input or #input == 0 then
			on_load({})
			return
		end

		local args = {
			"rg",
			"--vimgrep",
			"--smart-case",
			"--glob",
			"!node_modules/**",
			input,
		}
		if use_previous then
			vim.list_extend(args, keys(prev_search_results))
		else
			table.insert(args, ".")
		end
		local result = vim.system(args, { text = true }):wait()

		if result.stdout then
			local lines = vim.split(result.stdout, "\n", { trimempty = true })
			local entries = {}
			for i, line in ipairs(lines) do
				table.insert(entries, parse_rg_line(i, line))
			end

			prev_search_results = {}
			for _, entry in ipairs(entries) do
				prev_search_results[entry.fp] = true
			end
			on_load(entries)
		end
	end)
end

return M
