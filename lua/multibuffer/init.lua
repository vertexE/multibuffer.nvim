local M = {}

local ui = require("multibuffer.ui")
local state = require("multibuffer.state")

local lsp = require("multibuffer.sources.lsp")

--- @param entries table<multibuffer.Entry>
local open = function(entries)
	vim.cmd("tabnew")
	local winr = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_get_current_buf()
	state.set_entries(entries)
	ui.open(state.state(), {
		bufnr = bufnr,
		winr = winr,
	})
	local previous_mapping = {}
	for _, keymap in ipairs(vim.api.nvim_get_keymap("n")) do
		if keymap.lhs == "<tab>" or keymap.lhs == "<s-tab>" or "<enter>" then
			table.insert(previous_mapping, keymap)
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

	vim.api.nvim_create_autocmd("TabClosed", {
		group = vim.api.nvim_create_augroup("multibuffer.TabClosed", { clear = true }),
		callback = function()
			if not vim.api.nvim_win_is_valid(winr) then
				for _, map in ipairs(previous_mapping) do
					vim.fn.mapset(map)
				end
			end
		end,
	})
end

M.lsp_references = function()
	state.reset()
	ui.reset()
	lsp.symbol_references_entries(function(entries)
		open(entries)
	end)
end

M.lsp_diagnostics = function()
	state.reset()
	ui.reset()
	open(lsp.diagnostic_entries())
end

return M
