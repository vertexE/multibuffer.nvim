local M = {}

local draw = require("multibuffer.draw")
local state = require("multibuffer.state")
local config = require("multibuffer.config")

local lsp = require("multibuffer.sources.lsp")
local editor = require("multibuffer.sources.editor")
local qfx = require("multibuffer.sources.quickfix")
local grep = require("multibuffer.sources.grep")

local _state = {
	open = false,
}

---@param opts ?multibuffer.options
M.setup = function(opts)
	if opts then
		config.set_options(opts)
	end
end

--- @param entries table<multibuffer.Entry>
local open = function(entries)
	_state.open = true
	vim.cmd("tabnew")
	local tbnr = vim.api.nvim_win_get_tabpage(0)
	local winr = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_get_current_buf()
	state.set_entries(entries)
	draw.open(state.state(), {
		bufnr = bufnr,
		winr = winr,
	})

	vim.keymap.set("n", config.key("enter-file"), function()
		vim.cmd("tabclose")
		local entry = state.active()
		vim.api.nvim_set_current_buf(entry.bufnr)
		vim.cmd(string.format("normal! %dgg^zz", entry.lnum + 1))
	end)

	vim.keymap.set("n", config.key("forward"), function()
		state.next()
		draw.next(state.state())
	end)

	vim.keymap.set("n", config.key("backward"), function()
		state.previous()
		draw.previous(state.state())
	end)

	vim.keymap.set("n", config.key("quit"), function()
		if tbnr == vim.api.nvim_get_current_tabpage() then
			vim.cmd("tabclose")
		end
	end)

	vim.api.nvim_create_autocmd("TabClosed", {
		group = vim.api.nvim_create_augroup("multibuffer.tab.close", { clear = true }),
		callback = function()
			_state.open = false
		end,
	})
end

M.lsp_references = function()
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	lsp.symbol_references_entries(function(entries)
		open(entries)
	end)
end

---@param bufnr integer|nil
M.lsp_diagnostics = function(bufnr)
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	open(lsp.diagnostic_entries(bufnr))
end

---@param resume ?boolean run the search again on the previous grep results
M.grep = function(resume)
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	grep.search(function(entries)
		if #entries == 0 then
			vim.notify("no results")
			return
		end

		open(entries)
	end, resume)
end

M.marks = function()
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	open(editor.marks())
end

M.quickfix = function()
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	open(qfx.quickfix_entries())
end

--- open multibuffer for lsp definitions, optionally filtered by the given function
--- @param filter ?function(multibuffer.Entry): boolean
M.lsp_definitions = function(filter)
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	draw.reset()
	lsp.symbol_definiton_entries(function(entries)
		if #entries == 0 then
			vim.notify("no results")
			return
		end

		if filter then
			local filtered_entries = vim.iter(entries)
				:filter(function(e)
					return filter(e)
				end)
				:totable()
			open(filtered_entries)
			return
		else
			open(entries)
		end
	end)
end

return M
