-- Set theme and enable transparent background
-- Available themes:
    -- gruvbox
    -- onedark
    -- nord
   
vim.cmd("colorscheme nord")

vim.cmd([[
    autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
]])
