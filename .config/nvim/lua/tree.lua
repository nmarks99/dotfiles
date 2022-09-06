-- https://github.com/LunarVim/LunarVim/commit/dc6196ee295fa92b1a29a436be5d539f44475e29



vim.g.nvim_tree_follow = 1
-- vim.nvim_tree_auto_close = O.auto_close_tree
vim.g.nvim_tree_auto_ignore_ft = 'startify'
vim.g.nvim_tree_quit_on_open = 0

local view = require'nvim-tree.view'

local _M = {}
_M.toggle_tree = function()
    if view.win_open() then
        require'nvim-tree'.close()
        require'bufferline.state'.set_offset(0)
    else
        require'bufferline.state'.set_offset(31,'File Explorer')
        require'nvim-tree'.find_file(true)
    end
end

return _M

