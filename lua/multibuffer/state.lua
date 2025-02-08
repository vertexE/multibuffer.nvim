--- @class multibuffer.State
--- @field entries table<multibuffer.Entry>
--- @field pos integer

--- @class multibuffer.Entry
--- @field index integer
--- @field bufnr integer
--- @field lnum integer
--- @field col? integer
--- @field msg string
--- @field fp string filepath

local M = {}

--- @type multibuffer.State
local state = {
	entries = {},
	pos = 1,
}

--- @param entries table<multibuffer.Entry>
M.set_entries = function(entries)
	state.pos = 1
	state.entries = entries
end

--- @return multibuffer.Entry
M.active = function()
	if #state.entries == 0 or state.pos > #state.entries then
		vim.notify("multibuffer: unable to get active, invalid state", vim.log.levels.ERROR, {})
	end

	return state.entries[state.pos]
end

--- @return multibuffer.State
M.state = function()
	return state
end

M.reset = function()
	state.entries = {}
	state.pos = 1
end

M.next = function()
	if #state.entries == 0 then
		return
	end
	if state.pos == #state.entries then
		return
	end

	state.pos = state.pos + 1
end

M.previous = function()
	if state.pos == 1 then
		return
	end
	state.pos = state.pos - 1
end

return M
