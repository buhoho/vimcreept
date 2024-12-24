if exists("vimcrypt_encrypted_loaded")
    finish
endif
let vimcrypt_encrypted_loaded = 1

" use openssl to encrypt decrypt files.
" copied/adapted from https://github.com/MoserMichael/vimcrypt
" my changes;
"   - I have reverted to using cbc as our own improvement.
"   - Password confirmation when encrypting
"   - Now works with gvim.
"   - The password you enter will be kept in the script scope for the duration of the session.

if !exists("s:stored_passwords")
    let s:stored_passwords = {}
endif

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

    let l:filename = expand('%:p')  " full path
    let l:default = has_key(s:stored_passwords, l:filename) ? s:stored_passwords[l:filename] : ''
    let $OPENSSL_PASS = input('decrypt password: ', l:default)

    if l:cipher == "aes"
        let l:cipher = "aes-256-cbc -pbkdf2"
    endif
    if l:cipher == "bfa"
        let l:expr = "0,$!openssl bf -d -a -salt -pass env:OPENSSL_PASS"
    else
        let l:expr = "0,$!openssl " . l:cipher . " -d -salt -pass env:OPENSSL_PASS"
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

    let s:stored_passwords[l:filename] = $OPENSSL_PASS " if read success
    let $OPENSSL_PASS = ''

    set nobin
    set cmdheight&
    set shell&
    execute ":doautocmd BufReadPost ".expand("%:r")
    redraw!
endfunction

function! s:OpenSSLWritePre()
    call s:OpenSSLReadPre()

    let l:cipher = expand("<afile>:e") 
    let l:filename = expand('%:p')  " full path


    let l:default = has_key(s:stored_passwords, l:filename) ? s:stored_passwords[l:filename] : ''
    let l:pass1 = input('encryption password : ', l:default)
    let l:pass2 = input('encryption password (Confirm) :', l:default)

    if l:pass1 != l:pass2
        let l:pass1 = ''
        let l:pass2 = ''
	throw 'Password mismatch: Save operation aborted.'
    endif

    let $OPENSSL_PASS = l:pass1
    let l:pass1 = ''
    let l:pass2 = ''

    if l:cipher == "aes"
        let l:cipher = "aes-256-cbc -pbkdf2"
    endif
    if l:cipher == "bfa"
        let l:expr = "0,$!openssl bf  -e -a -salt -pass env:OPENSSL_PASS"
    else
        let l:expr = "0,$!openssl " . l:cipher . " -e -salt -pass env:OPENSSL_PASS"
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
    let s:stored_passwords[l:filename] = $OPENSSL_PASS " temporary on memory
    let $OPENSSL_PASS = ''
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


