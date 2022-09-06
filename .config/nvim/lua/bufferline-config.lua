-- bufferline setup
require('bufferline').setup {
    options = {
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        offsets = {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true
        }
    }
}
vim.cmd("nnoremap <silent>b] :BufferLineCycleNext<CR>")
vim.cmd("nnoremap <silent>b[ :BufferLineCyclePrev<CR>")


