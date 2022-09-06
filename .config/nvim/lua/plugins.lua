local paq = require("paq")
paq {
    "savq/paq-nvim";
    
    -- file explorer
    -- 'preservim/nerdtree';
    -- 'tiagofumo/vim-nerdtree-syntax-highlight';
    -- 'Xuyuanp/nerdtree-git-plugin';

    -- 'ryanoasis/vim-devicons'; 

    'kyazdani42/nvim-tree.lua'; 
    
    -- tabs like ide
    -- 'akinsho/bufferline.nvim';
    'romgrk/barbar.nvim';
    
    -- lualine for info at bottom 
    'nvim-lualine/lualine.nvim';

    -- Code completion and linting 
    {'ms-jpq/coq_nvim', branch = 'coq'};
    {'ms-jpq/coq.artifacts', branch = 'artifacts'};
    {'ms-jpq/coq.thirdparty', branch = '3p'};
    -- {'neoclide/coc.nvim', branch = "release"};
    'sheerun/vim-polyglot'; -- all in one syntax highlighting

    -- themes
    'joshdick/onedark.vim';

    -- misc
    'kyazdani42/nvim-web-devicons'; -- nicer icons
    'numirias/semshi'; -- python highlighter
    'chrisbra/sudoedit.vim'; -- sudo nvim for editing readonlys
    'ap/vim-css-color'; -- display color with CSS color codes
    'preservim/nerdcommenter'; -- comment stuff
}
