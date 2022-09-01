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

    -- misc
    'kyazdani42/nvim-web-devicons';
    'joshdick/onedark.vim';
    -- 'itchyny/lightline.vim';
    'nvim-lualine/lualine.nvim',

}

vim.opt.termguicolors = true
require('bufferline').setup {}

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

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}