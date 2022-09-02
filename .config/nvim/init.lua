require "lua.plugins" 
-- require "lua.coc"

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


-- bufferline setup
require('bufferline').setup {
    options = {
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        offsets = {
            filetype = "NERDTree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true
        }
    }
}
vim.cmd("nnoremap <silent>b] :BufferLineCycleNext<CR>")
vim.cmd("nnoremap <silent>b[ :BufferLineCyclePrev<CR>")



-- Set theme and enable transparent background
vim.cmd([[
    colorscheme onedark
    autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
]])

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


-- nerdtree settings
vim.cmd([[
    " NERDTree
    map <C-n> :NERDTreeToggle<CR>
    " NERDTree
    let g:NERDTreeShowHidden = 1 
    let g:NERDTreeMinimalUI = 1 " hide helper
    let g:NERDTreeIgnore = ['^node_modules$'] " ignore node_modules to increase load speed 
    let g:NERDTreeStatusline = '' " set to empty to use lightline
    " " Toggle
    noremap <silent> <C-b> :NERDTreeToggle<CR>
    " " Close window if NERDTree is the last one
    autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    " " Map to open current file in NERDTree and set size
    nnoremap <leader>pv :NERDTreeFind<bar> :vertical resize 45<CR>

    " NERDTree Syntax Highlight
    " " Enables folder icon highlighting using exact match
    let g:NERDTreeHighlightFolders = 1 
    " " Highlights the folder name
    let g:NERDTreeHighlightFoldersFullName = 1 
    " " Color customization
    let s:brown = "905532"
    let s:aqua =  "3AFFDB"
    let s:blue = "689FB6"
    let s:darkBlue = "44788E"
    let s:purple = "834F79"
    let s:lightPurple = "834F79"
    let s:red = "AE403F"
    let s:beige = "F5C06F"
    let s:yellow = "F09F17"
    let s:orange = "D4843E"
    let s:darkOrange = "F16529"
    let s:pink = "CB6F6F"
    let s:salmon = "EE6E73"
    let s:green = "8FAA54"
    let s:lightGreen = "31B53E"
    let s:white = "FFFFFF"
    let s:rspec_red = 'FE405F'
    let s:git_orange = 'F54D27'
    " " This line is needed to avoid error
    let g:NERDTreeExtensionHighlightColor = {} 
    " " Sets the color of css files to blue
    let g:NERDTreeExtensionHighlightColor['css'] = s:blue 
    " " This line is needed to avoid error
    let g:NERDTreeExactMatchHighlightColor = {} 
    " " Sets the color for .gitignore files
    let g:NERDTreeExactMatchHighlightColor['.gitignore'] = s:git_orange 
    " " This line is needed to avoid error
    let g:NERDTreePatternMatchHighlightColor = {} 
    " " Sets the color for files ending with _spec.rb
    let g:NERDTreePatternMatchHighlightColor['.*_spec\.rb$'] = s:rspec_red 
    " " Sets the color for folders that did not match any rule
    let g:WebDevIconsDefaultFolderSymbolColor = s:beige 
    " " Sets the color for files that did not match any rule
    let g:WebDevIconsDefaultFileSymbolColor = s:blue 

    " NERDTree Git Plugin
    let g:NERDTreeGitStatusIndicatorMapCustom = {
        \ "Modified"  : "✹",
        \ "Staged"    : "✚",
        \ "Untracked" : "✭",
        \ "Renamed"   : "➜",
        \ "Unmerged"  : "═",
        \ "Deleted"   : "✖",
        \ "Dirty"     : "✗",
        \ "Clean"     : "✔︎",
        \ 'Ignored'   : '☒',
        \ "Unknown"   : "?"
        \}
]])

-- lualine
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = auto,
    }
}
