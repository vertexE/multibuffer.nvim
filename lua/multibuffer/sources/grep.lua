local M = {}

local previous_entry_filepaths = {}

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
	vim.ui.input({ prompt = "grep" }, function(input)
		if not input or #input == 0 then
			on_load({})
			return
		end

		local result = vim.system({
			"rg",
			"--vimgrep",
			"--smart-case",
			"--glob",
			"!node_modules/**",
			input,
			use_previous and table.concat(previous_entry_filepaths, " ") or ".",
		}, { text = true }):wait()
		if result.stdout then
			local lines = vim.split(result.stdout, "\n", { trimempty = true })
			local entries = {}
			for i, line in ipairs(lines) do
				table.insert(entries, parse_rg_line(i, line))
			end

			previous_entry_filepaths = vim.iter(entries)
				:map(function(entry)
					return entry.fp
				end)
				:totable()
			on_load(entries)
		else
			on_load({})
		end
	end)
end

return M
