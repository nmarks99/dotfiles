require "lua.plugins"
require "lua.tree"
require "lua.theme"
require "lua.barbar"

-- general settings 
vim.opt.compatible = false              -- disable compatibility with old-time vi
vim.opt.showmatch = true                -- show matching brackets
vim.opt.ignorecase = true               --case sensative matching
vim.opt.hlsearch = true                 --highlight search results 
vim.opt.tabstop = 4                     --number of columns occupied by a tab character
vim.opt.softtabstop = 4                 -- set multiple spaces as tab stops so <BS> does the right thing
vim.opt.shiftwidth = 4                  -- width for auto indents
vim.opt.autoindent = true               --indent new line same amount as one just typed
vim.opt.number = true                   -- add line numbers 
vim.opt.expandtab = true                -- converts tabs to white space
vim.cmd("filetype plugin indent on")    -- auto-indents based on plugin type
vim.cmd("set mouse+=a")                 -- enable mouse
vim.cmd("set wildmode=longest,list")    -- get bash-like tab completions
vim.cmd("syntax on")                    -- enable syntax highlighting
vim.opt.termguicolors = true



-- nerd commenter
vim.cmd([[
" " Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" " Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" " Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" " Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

" " Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" " Map ++ to call NERD Commenter and use iTerm key bindings 
vmap ++ <plug>NERDCommenterToggle
nmap ++ <plug>NERDCommenterToggle

]])


-- lualine
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = auto,
    }
}
