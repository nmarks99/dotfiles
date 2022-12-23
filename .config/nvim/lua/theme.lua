-- Set theme and enable transparent background
-- Available themes:
    -- gruvbox
    -- onedark
    -- nord
    -- catpuccin
    
vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha
require("catppuccin").setup({
    transparent_background = false
})

vim.cmd [[colorscheme catppuccin]]

-- use this to set transparent background if needed
-- vim.cmd([[
    -- autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    -- autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
-- ]])
