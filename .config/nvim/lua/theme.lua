
-- handles transparent background
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
require("catppuccin").setup({
    transparent_background = false
})

-- use this to set transparent background if needed (non-catpuccin)
-- vim.cmd([[
    -- autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
    -- autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
-- ]])


-- sets the default theme
vim.cmd [[colorscheme gruvbox]]
