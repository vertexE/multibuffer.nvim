local M = {}

--- @return table<multibuffer.Entry>
M.quickfix_entries = function()
	local quickfix_list = vim.fn.getqflist()
	local entries = {}
	for i, item in ipairs(quickfix_list) do
		if item.bufnr then
			local name = vim.api.nvim_buf_get_name(item.bufnr)
			local path = vim.fn.fnamemodify(name, ":~:.")
			table.insert(entries, {
				id = i,
				bufnr = item.bufnr,
				lnum = item.lnum - 1, -- lnum is 1-based, convert to 0-based
				msg = item.text,
				fp = path,
			})
		end
	end

	return entries
end

return M
