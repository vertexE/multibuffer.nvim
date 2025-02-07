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
		if keymap.lhs == "<tab>" or keymap.lhs == "<s-tab>" then
			table.insert(previous_mapping, keymap)
		end
	end

	-- need to do the same thing for space-q to ensure we can
	-- close the tab with "tabclose"

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
			if vim.api.nvim_win_is_valid(winr) then
				for _, map in ipairs(previous_mapping) do
					vim.fn.mapset(map)
				end
			end
		end,
	})
end

M.lsp_diagnostics = function()
	state.reset() -- ensure we have a clean slate
	ui.reset()
	open(lsp.diagnostic_entries())
end

return M
