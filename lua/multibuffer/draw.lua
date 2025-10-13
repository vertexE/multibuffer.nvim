local M = {}

--- @class multibuffer.Context
--- @field bufnr integer
--- @field winr integer

local PREVIEW_SIZE = 7

--- @class multibuffer.Placement
--- @field id integer
--- @field bufnr integer
--- @field lnum integer
--- @field msg string
--- @field fp string filepath
--- @field severity ?vim.diagnostic.Severity
--- @field lazy ?boolean if true, then bufnr is -1 and we need to load the file into a buffer first

--- @type table<integer,multibuffer.Placement>
local placement = {}

--- @type table<integer>
local windows = {}

local cursor = 1

---@param entry multibuffer.Entry|multibuffer.Placement
---@param total integer
---@return table<table<string>>
local title = function(entry, total)
	local buf_name = vim.api.nvim_buf_get_name(entry.bufnr)
	local name = vim.fn.fnamemodify(buf_name, ":t")
	return {
		{ string.format("%d/%d ", entry.index or entry.id, total), "MiniIconsOrange" },
		{ name .. string.format(":%d", entry.lnum), "Comment" },
	}
end

--- @param lnum integer
local scroll_in = function(winr, lnum)
	local prev_winr = vim.api.nvim_get_current_win()
	vim.api.nvim_set_current_win(winr)
	vim.cmd(string.format("normal! %dgg^zz", lnum))
	vim.api.nvim_set_current_win(prev_winr)
end

--- @param state multibuffer.State
M.next = function(state)
	if cursor == #windows then
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
			if next_entry.lazy and next_entry.bufnr == -1 then
				next_entry.bufnr = vim.uri_to_bufnr(vim.uri_from_fname(next_entry.fp))
				vim.fn.bufload(next_entry.bufnr)
			end
			for i, _winr in ipairs(windows) do
				if i == #windows then
					vim.api.nvim_win_set_buf(_winr, next_entry.bufnr)
					scroll_in(_winr, next_entry.lnum + 1)
					placement[_winr] = {
						id = next_entry.index,
						bufnr = next_entry.bufnr,
						lnum = next_entry.lnum,
						msg = next_entry.msg,
						fp = next_entry.fp,
						severity = next_entry.severity,
						lazy = next_entry.lazy,
					}
				else
					local next_pl = placement[windows[i + 1]]
					placement[_winr] = next_pl
					vim.api.nvim_win_set_buf(_winr, placement[_winr].bufnr)
					scroll_in(_winr, placement[_winr].lnum + 1)
				end
				vim.wo[_winr].winbar = ""
				local entry = placement[_winr]
				vim.api.nvim_win_set_config(_winr, { title = title(entry, #state.entries) })
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
					msg = prev_entry.msg,
					fp = prev_entry.fp,
					severity = prev_entry.severity,
					lazy = prev_entry.lazy,
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
			vim.api.nvim_win_set_config(_winr, { title = title(entry, #state.entries) })
		end
	end
end

-- TODO: further improve disabling scroll and if you try to go out of bounds it will
-- take you to the next item

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

		if entry.lazy and entry.bufnr == -1 then
			entry.bufnr = vim.uri_to_bufnr(vim.uri_from_fname(entry.fp))
			vim.fn.bufload(entry.bufnr)
		end

		local _winr = vim.api.nvim_open_win(entry.bufnr, false, {
			title = title(entry, #state.entries),
			border = { " ", " ", " ", " ", " ", "─", " ", " " }, -- ─
			relative = "win",
			row = ((i - 1) * (PREVIEW_SIZE + 2)),
			col = 0,
			height = PREVIEW_SIZE,
			width = vim.api.nvim_win_get_width(0),
			zindex = 1,
		})
		scroll_in(_winr, entry.lnum + 1)
		vim.wo[_winr].winbar = ""
		vim.wo[_winr].scrolloff = 0
		table.insert(windows, _winr)
		placement[_winr] = {
			id = entry.index,
			bufnr = entry.bufnr,
			lnum = entry.lnum,
			msg = entry.msg,
			fp = entry.fp,
			severity = entry.severity,
			lazy = entry.lazy,
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
