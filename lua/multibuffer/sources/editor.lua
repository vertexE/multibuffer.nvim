local M = {}

--- @return table<multibuffer.Entry>
M.marks = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local marks = { "a", "b", "c", "d", "e", "f", "g" }
	local entries = {}
	for _, mark in ipairs(marks) do
		local pos = vim.api.nvim_buf_get_mark(bufnr, mark)
		vim.print(mark, pos)
		local name = vim.api.nvim_buf_get_name(bufnr)
		local path = vim.fn.fnamemodify(name, ":~:.")
		if pos[1] ~= 0 or pos[2] ~= 0 then
			table.insert(entries, {
				index = #entries + 1,
				bufnr = bufnr,
				lnum = pos[1] - 1,
				col = pos[2],
				msg = mark,
				fp = path,
			})
		end
	end

	return entries
end

return M
