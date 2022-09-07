vim.api.nvim_create_user_command(
    'HELLO',
    function(opts)
        print(opts.args)
    end,
    { nargs = 1 }
)

