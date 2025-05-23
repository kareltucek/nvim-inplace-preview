" plugin/inplace-preview.vim
" Inplace Preview Plugin - Show transformed versions of code in-place

if exists('g:loaded_inplace_preview')
    finish
endif
let g:loaded_inplace_preview = 1

" Default configuration
if !exists('g:inplace_preview_cmd')
    let g:inplace_preview_cmd = 'cat'
endif

if !exists('g:inplace_preview_toggle_key')
    let g:inplace_preview_toggle_key = '<leader>p'
endif

" Commands
command! InplacePreviewToggle lua require('inplace-preview').toggle_preview()
command! InplacePreviewShow lua require('inplace-preview').show_preview()
command! InplacePreviewHide lua require('inplace-preview').restore_original()

" Auto-setup when Neovim starts
augroup InplacePreviewInit
    autocmd!
    autocmd VimEnter * lua require('inplace-preview').setup()
augroup END

" Optional statusline function
function! InplacePreviewStatus()
    if luaeval('require("inplace-preview").is_preview_active()')
        return '[PREVIEW]'
    else
        return ''
    endif
endfunction
