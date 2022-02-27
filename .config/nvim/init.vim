set nocompatible            " disable compatibility to old-time vi
set showmatch               " show matching brackets.
set ignorecase              " case insensitive matching
set mouse=v                 " middle-click paste with mouse
set hlsearch                " highlight search results
set tabstop=4               " number of columns occupied by a tab character
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
"set number                  " add line numbers
set wildmode=longest,list   " get bash-like tab completions
"set cc=80                   " set an 80 column border for good coding style
filetype plugin indent on   " allows auto-indenting depending on file type
syntax on                   " syntax highlighting




call plug#begin('~/.local/share/nvim/plugged')
    Plug 'preservim/nerdtree'
    Plug 'sainnhe/everforest'
    Plug 'joshdick/onedark.vim'
    Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }
    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
    Plug 'chrisbra/sudoedit.vim'
    Plug 'nvim-lualine/lualine.nvim'
    Plug 'kyazdani42/nvim-web-devicons'
call plug#end()

map <C-n> :NERDTreeToggle<CR>
syntax on 
colorscheme onedark
autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE






