
vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha
require("catppuccin").setup({
    transparent_background = true
})

-- This sets the colorscheme in the usual way
-- vim.cmd [[colorscheme gruvbox]]

-- use this to set transparent background if needed
-- vim.cmd([[
    -- autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    -- autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
-- ]])
