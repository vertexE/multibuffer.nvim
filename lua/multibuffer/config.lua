local M = {}

--- @class multibuffer.lsp.options
--- @field unique ?boolean  whether to filter out definitions that go to the same line, by default true

--- @class multibuffer.options
--- @field lsp ?multibuffer.lsp.options
--- @field keys table<string,multibuffer.actions>

--- @alias multibuffer.actions "enter-file"|"forward"|"backward"|"quit"

--- @type multibuffer.options
local default_options = {
	keys = {
		["<enter>"] = "enter-file",
		["<tab>"] = "forward",
		["<s-tab>"] = "backward",
		["q"] = "quit",
	},
	lsp = {
		unique = true,
	},
}

M.options = function()
	return default_options
end

---@param find_action multibuffer.actions
---@return string keybind for the given action
M.key = function(find_action)
	for keybind, action in pairs(default_options.keys) do
		if action == find_action then
			return keybind
		end
	end
	return ""
end

---@param opts multibuffer.options
M.set_options = function(opts)
	if opts.lsp then
		default_options.lsp = vim.tbl_extend("force", default_options.lsp, opts.lsp)
	end
	if opts.keys then
		default_options.keys = vim.tbl_extend("force", default_options.keys, opts.keys)
	end
end

return M
