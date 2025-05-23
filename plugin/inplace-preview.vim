" plugin/inplace-preview.vim
" Inplace Preview Plugin - Show transformed versions of code in-place

if exists('g:loaded_inplace_preview')
    finish
endif
let g:loaded_inplace_preview = 1

" Commands
command! InplacePreviewToggle lua require('inplace-preview').toggle_preview()
command! InplacePreviewShow lua require('inplace-preview').show_preview()
command! InplacePreviewHide lua require('inplace-preview').restore_original()

" Optional statusline function
function! InplacePreviewStatus()
    if luaeval('require("inplace-preview").is_preview_active()')
        return '[PREVIEW]'
    else
        return ''
    endif
endfunction
