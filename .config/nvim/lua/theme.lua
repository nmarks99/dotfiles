
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
require("catppuccin").setup({
    transparent_background = false
})

vim.cmd [[colorscheme catppuccin]]

-- use this to set transparent background if needed
-- vim.cmd([[
    -- autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    -- autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
-- ]])
