local M = {}

local ui = require("multibuffer.ui")
local state = require("multibuffer.state")

local lsp = require("multibuffer.sources.lsp")

local keys = { -- TODO: these belong in setup options
	"<tab>",
	"<s-tab>",
	"<enter>",
	"q",
}

local _state = {
	open = false,
}

--- @param entries table<multibuffer.Entry>
local open = function(entries)
	_state.open = true
	vim.cmd("tabnew")
	local tbnr = vim.api.nvim_win_get_tabpage(0)
	local winr = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_get_current_buf()
	state.set_entries(entries)
	ui.open(state.state(), {
		bufnr = bufnr,
		winr = winr,
	})
	local previous_keymaps = {}
	for _, keymap in ipairs(vim.api.nvim_get_keymap("n")) do
		if vim.tbl_contains(keys, keymap.lhs) then
			previous_keymaps[keymap.lhs] = keymap
		end
	end

	vim.keymap.set("n", "<enter>", function()
		vim.cmd("tabclose")
		local entry = state.active()
		vim.api.nvim_set_current_buf(entry.bufnr)
		vim.cmd(string.format("normal! %dgg^zz", entry.lnum + 1))
	end)

	vim.keymap.set("n", "<tab>", function()
		state.next()
		ui.next(state.state())
	end)

	vim.keymap.set("n", "<s-tab>", function()
		state.previous()
		ui.previous(state.state())
	end)

	vim.keymap.set("n", "q", function()
		if tbnr == vim.api.nvim_get_current_tabpage() then
			vim.cmd("tabclose")
		end
	end)

	vim.api.nvim_create_autocmd("TabClosed", {
		group = vim.api.nvim_create_augroup("multibuffer.TabClosed", { clear = true }),
		callback = function()
			if not _state.open then
				return -- don't modify keymaps if the multibuffer wasn't open
			end

			_state.open = false
			if not vim.tbl_contains(vim.api.nvim_list_tabpages(), tbnr) then
				for _, key in pairs(keys) do
					if previous_keymaps[key] then
						vim.fn.mapset(previous_keymaps[key])
					else
						vim.api.nvim_del_keymap("n", key)
					end
				end
			end
		end,
	})
end

M.lsp_references = function()
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	ui.reset()
	lsp.symbol_references_entries(function(entries)
		open(entries)
	end)
end

M.lsp_diagnostics = function()
	if _state.open then
		vim.notify("multibuffer already open", vim.log.levels.WARN, {})
		return
	end
	state.reset()
	ui.reset()
	open(lsp.diagnostic_entries())
end

return M
