if exists("vimcrypt_encrypted_loaded")
    finish
endif
let vimcrypt_encrypted_loaded = 1

" use openssl to encrypt decrypt files.
" copied/adapted from https://github.com/vim-scripts/openssl.vim/blob/master/plugin/openssl.vim
" my changes;
"   - use aes-ecb instead of aes-cbc. Reason: if file gets damaged then with cbc
"   everything is lost after the damage point, ecb mode is good enough for text)
"   - turn off shelltemp and undofile when working with encrypted stuff.
"   - throw out the password safe stuff, I don't need it.
"   - exclude vulnerable ciphers from the list of supported file extensions
"
function! s:OpenSSLReadPre()
    set cmdheight=3
    set viminfo=
    if &undofile != 0
        set noundofile
    endif
    if &swapfile != 0
        set noswapfile
    endif
    if &shelltemp != 0
        set noshelltemp
    endif
    set shell=/bin/sh
    set bin
endfunction

function! s:OpenSSLReadPost()
    let l:cipher = expand("%:e")
    if l:cipher == "aes"
        let l:cipher = "aes-256-ecb"
    endif
    if l:cipher == "bfa"
        let l:cipher = "bf"
        let l:expr = "0,$!openssl " . l:cipher . " -d -a -salt"
    else
        let l:expr = "0,$!openssl " . l:cipher . " -d -salt"
    endif

    silent! execute l:expr
    if v:shell_error
        silent! 0,$y
        silent! undo
        echo "COULD NOT DECRYPT USING EXPRESSION: " . expr
        echo "Note that your version of openssl may not have the given cipher engine built-in"
        echo "even though the engine may be documented in the openssl man pages."
        echo "ERROR FROM OPENSSL:"
        echo @"
        echo "COULD NOT DECRYPT"
        return
    endif
    set nobin
    set cmdheight&
    set shell&
    execute ":doautocmd BufReadPost ".expand("%:r")
    redraw!
endfunction

function! s:OpenSSLWritePre()
    call s:OpenSSLReadPre()

    let l:cipher = expand("<afile>:e") 
    if l:cipher == "aes"
        let l:cipher = "aes-256-ecb"
    endif
    if l:cipher == "bfa"
        let l:cipher = "bf"
        let l:expr = "0,$!openssl " . l:cipher . " -e -a -salt"
    else
        let l:expr = "0,$!openssl " . l:cipher . " -e -salt"
    endif

    "backup the file.
    if filereadable(expand("<afile>"))
        let s:cmd = "cp -f ". expand("<afile>") . " " . expand("<afile>") . ".bak"
        call system(s:cmd)
    endif

    silent! execute l:expr
    if v:shell_error
        silent! 0,$y
        silent! undo
        echo "COULD NOT ENCRYPT USING EXPRESSION: " . expr
        echo "Note that your version of openssl may not have the given cipher engine built in"
        echo "even though the engine may be documented in the openssl man pages."
        echo "ERROR FROM OPENSSL:"
        echo @"
        echo "COULD NOT ENCRYPT"
        return
    endif
endfunction

function! s:OpenSSLWritePost()
    silent! undo
    set nobin
    set shell&
    set cmdheight&
    redraw!
endfunction

autocmd BufReadPre,FileReadPre     *.aes,*.cast,*.rc5,*.desx call s:OpenSSLReadPre()
autocmd BufReadPost,FileReadPost   *.aes,*.cast,*.rc5,*.desx call s:OpenSSLReadPost()
autocmd BufWritePre,FileWritePre   *.aes,*.cast,*.rc5,*.desx call s:OpenSSLWritePre()
autocmd BufWritePost,FileWritePost *.aes,*.cast,*.rc5,*.desx call s:OpenSSLWritePost()


