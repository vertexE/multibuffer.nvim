local M = {}

--- @class multibuffer.lsp.definition.options
--- @field unique ?boolean whether to filter out definitions that go to the same line

--- @class multibuffer.lsp.options
--- @field definition ?multibuffer.lsp.definition.options

--- @class multibuffer.options
--- @field lsp ?multibuffer.lsp.options

--- @type multibuffer.options
local default_options = {
	lsp = {
		definition = {
			unique = false,
		},
	},
}

M.options = function()
	return default_options
end

---@param opts ?multibuffer.options
M.set = function(opts)
	if opts and opts.lsp and opts.lsp.definition then
		default_options.lsp.definition = vim.tbl_extend("force", default_options.lsp.definition, opts.lsp.definition)
	end
end

return M
