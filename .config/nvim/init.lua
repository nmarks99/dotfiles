local paq = require("paq")
paq {
    "savq/paq-nvim";
    -- 'preservim/nerdtree';
    'kyazdani42/nvim-web-devicons';
    'akinsho/bufferline.nvim'
}

vim.opt.termguicolors = true
require('bufferline').setup {}
