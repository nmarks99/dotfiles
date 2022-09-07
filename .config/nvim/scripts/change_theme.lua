local function is_in (val, arr)
    for index, value in ipairs(arr) do
        if value == val then
            return true
        end
    end

    return false
end

local function update_theme(new_theme)
    local filename = "asdf.lua"
    local filehandle = io.open(filename,"w+")
    filehandle:write(string.format("vim.cmd('colorscheme %s')",new_theme))
    filehandle:write("vim.cmd('autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE')")
    filehandle:write("vim.cmd('autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE')")
    filehandle:close()
end


vim.api.nvim_create_user_command(
    'ChangeTheme',
    function(opts)
        local new_theme = opts.args
        local theme_ops = {"gruvbox", "nord", "onedark"}
        if is_in(new_theme,theme_ops) then
            local cmd_str = string.format("colorscheme %s",new_theme)
            vim.cmd(cmd_str)
            vim.cmd([[
                autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
                autocmd vimenter * hi NonText guibg=NONE ctermbg=NONE
            ]])
        else
            error(string.format("Theme '%s' not available",new_theme))
        end

    end,
    { nargs = 1 }
)

