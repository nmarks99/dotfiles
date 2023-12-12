---@type ChadrcConfig 
local M = {}
M.ui = {theme = 'ayu_dark', transparency=true}
M.plugins = 'custom.plugins'
M.mappings = require "custom.mappings"
vim.opt.softtabstop = 4
return M

