local paq = require("paq")
paq {
    "savq/paq-nvim";
    

    -- file explorer
    'kyazdani42/nvim-tree.lua'; 
    
    -- tabs
    'romgrk/barbar.nvim';
    
    -- lualine for info at bottom 
    'nvim-lualine/lualine.nvim';

    -- code completion and linting 
    {'neoclide/coc.nvim', branch = "release"};
    'sheerun/vim-polyglot'; -- all in one syntax highlighting

    -- themes
    'joshdick/onedark.vim';
    'morhetz/gruvbox';
    'shaunsingh/nord.nvim';
    { "catppuccin/nvim", as = "catppuccin" };

    -- misc
    'kyazdani42/nvim-web-devicons'; -- nicer icons
    -- 'numirias/semshi'; -- python highlighter
    'chrisbra/sudoedit.vim'; -- sudo nvim for editing readonlys
    'ap/vim-css-color'; -- display color with CSS color codes
    'preservim/nerdcommenter'; -- comment stuff
}
