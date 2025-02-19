local M = {}

--- @class multibuffer.Context
--- @field bufnr integer
--- @field winr integer

local PREVIEW_SIZE = 7

--- @class multibuffer.Placement
--- @field id integer
--- @field bufnr integer
--- @field lnum integer

--- @type table<integer,multibuffer.Placement>
local placement = {
	-- _winr = bufnr, ?? do I need lnum, id
}

--- @type table<integer>
local windows = {}

local cursor = 1

--- @param bufnr integer
--- @return string
local path = function(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return vim.fn.fnamemodify(name, ":~:.")
end

--- @param lnum integer
local scroll_in = function(winr, lnum)
	local prev_winr = vim.api.nvim_get_current_win()
	vim.api.nvim_set_current_win(winr)
	vim.cmd(string.format("normal! %dgg^", lnum))
	vim.api.nvim_set_current_win(prev_winr)
end

--- @param state multibuffer.State
M.next = function(state)
	if cursor == #windows then
		vim.notify("multibuffer: last item", vim.log.levels.INFO, {})
		return
	end
	if cursor < (math.floor(#windows / 2) + 1) then
		cursor = cursor + 1
		local win = windows[cursor]
		vim.api.nvim_set_current_win(win)
	else -- cursor is now in the "middle" of the parent window
		local next_entry = state.entries[placement[windows[#windows]].id + 1]
		if not next_entry then
			cursor = cursor + 1
			local win = windows[cursor]
			vim.api.nvim_set_current_win(win)
		else
			for i, _winr in ipairs(windows) do
				if i == #windows then
					vim.api.nvim_win_set_buf(_winr, next_entry.bufnr)
					scroll_in(_winr, next_entry.lnum + 1)
					placement[_winr] = {
						id = next_entry.index,
						bufnr = next_entry.bufnr,
						lnum = next_entry.lnum,
					}
				else
					local next_pl = placement[windows[i + 1]]
					placement[_winr] = next_pl
					vim.api.nvim_win_set_buf(_winr, placement[_winr].bufnr)
					scroll_in(_winr, placement[_winr].lnum + 1)
				end
				vim.wo[_winr].winbar = ""
				local entry = placement[_winr]
				vim.api.nvim_win_set_config(_winr, { title = path(entry.bufnr) .. string.format(":%d", entry.lnum) })
			end
		end
	end
end

--- @param state multibuffer.State
M.previous = function(state)
	if cursor == 1 then
		return
	end

	local prev_entry = state.entries[placement[windows[1]].id - 1]
	if not prev_entry then
		cursor = cursor - 1
		local prev_win = windows[cursor]
		vim.api.nvim_set_current_win(prev_win)
	else
		for i = #windows, 1, -1 do
			local _winr = windows[i]
			if i == 1 then
				placement[_winr] = {
					id = prev_entry.index,
					bufnr = prev_entry.bufnr,
					lnum = prev_entry.lnum,
				}
				vim.api.nvim_win_set_buf(_winr, placement[_winr].bufnr)
				scroll_in(_winr, prev_entry.lnum + 1)
			else
				placement[_winr] = placement[windows[i - 1]]
				vim.api.nvim_win_set_buf(_winr, placement[_winr].bufnr)
				scroll_in(_winr, placement[_winr].lnum + 1)
			end
            vim.wo[_winr].winbar = ""
			local entry = placement[_winr]
			vim.api.nvim_win_set_config(_winr, { title = path(entry.bufnr) .. string.format(":%d", entry.lnum) })
		end
	end
end

--- open floats to fill the current window based on PREVIEW_SIZE
--- setting the cursor into the top window
--- @param state multibuffer.State
--- @param ctx multibuffer.Context
M.open = function(state, ctx)
	if #state.entries == 0 then
		vim.notify("multibuffer: no items", vim.log.levels.WARN, {})
		return
	end

	local max_height = vim.api.nvim_win_get_height(ctx.winr)
	for i, entry in ipairs(state.entries) do
		if (i * (PREVIEW_SIZE + 1)) > max_height then
			break
		end

		local _winr = vim.api.nvim_open_win(entry.bufnr, false, {
			title = path(entry.bufnr) .. string.format(":%d", entry.lnum),
			border = "rounded",
			relative = "win",
			row = ((i - 1) * (PREVIEW_SIZE + 2)),
			col = 0,
			height = PREVIEW_SIZE,
			width = vim.api.nvim_win_get_width(0),
			zindex = 1,
		})
		scroll_in(_winr, entry.lnum + 1)
		vim.wo[_winr].winbar = ""
		table.insert(windows, _winr)
		placement[_winr] = {
			id = entry.index,
			bufnr = entry.bufnr,
			lnum = entry.lnum,
		}
	end
	vim.api.nvim_set_current_win(windows[1])
end

--- refresh the window list
--- @param state multibuffer.State
--- @param ctx multibuffer.Context
M.refresh = function(state, ctx)
	M.reset()
	M.open(state, ctx)
end

M.reset = function()
	cursor = 1
	placement = {}
	for _, winr in ipairs(windows) do
		if vim.api.nvim_win_is_valid(winr) then
			vim.api.nvim_win_close(winr, true)
		end
	end
	windows = {}
end

return M
