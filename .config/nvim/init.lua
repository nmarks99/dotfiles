local paq = require("paq")
paq {
    "savq/paq-nvim";
    
    -- nerdtree
    'preservim/nerdtree';
    'tiagofumo/vim-nerdtree-syntax-highlight';
    'Xuyuanp/nerdtree-git-plugin';
    'ryanoasis/vim-devicons'; 
    
    -- bufferline
    'akinsho/bufferline.nvim';

    -- Code completion and linting 
    {'neoclide/coc.nvim', branch = "release"};
    'sheerun/vim-polyglot';


    -- misc
    'kyazdani42/nvim-web-devicons';
    'joshdick/onedark.vim';
    'nvim-lualine/lualine.nvim',

}

vim.opt.termguicolors = true
require("bufferline").setup{}

vim.opt.compatible = false
vim.opt.showmatch = true
vim.opt.hlsearch = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.cmd("set wildmode=longest,list")
vim.cmd("syntax on")

-- Set theme and enable transparent background
vim.cmd([[
    colorscheme onedark
    autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
]])



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









require('lualine').setup {
--   options = {
--     icons_enabled = true,
--     theme = 'auto',
--     component_separators = { left = '', right = ''},
--     section_separators = { left = '', right = ''},
--     disabled_filetypes = {
--       statusline = {},
--       winbar = {},
--     },
--     ignore_focus = {},
--     always_divide_middle = true,
--     globalstatus = false,
--     refresh = {
--       statusline = 1000,
--       tabline = 1000,
--       winbar = 1000,
--     }
--   },
--   sections = {
--     lualine_a = {'mode'},
--     lualine_b = {'branch', 'diff', 'diagnostics'},
--     lualine_c = {'filename'},
--     lualine_x = {'encoding', 'fileformat', 'filetype'},
--     lualine_y = {'progress'},
--     lualine_z = {'location'}
--   },
--   inactive_sections = {
--     lualine_a = {},
--     lualine_b = {},
--     lualine_c = {'filename'},
--     lualine_x = {'location'},
--     lualine_y = {},
--     lualine_z = {}
--   },
--   tabline = {},
--   winbar = {},
--   inactive_winbar = {},
--   extensions = {}
}