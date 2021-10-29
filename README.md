# VIMCRYPT vim plugin - encrypt your files with openssl

This code has been derived from [openssl.vim](https://github.com/vim-scripts/openssl.vim/blob/master/plugin/openssl.vim)

It will you openssl to encrypt/decryt any text file with the following extensions:  ``` *.aes,*.cast,*.rc5,*.desx ```

It prompts you for a password while reading and writing these files.

My changes on top of openssl.vim:

   - use aes-256-ecb instead of aes-256-cbc. Reason: if the file gets damaged, then all the data after the damage point is lost, when using cipher block chaining (cbc). The damage would be limited to block with the damaged byte, when using ecb.
   - turn off vim options ```shelltemp``` and ```undofile``` when working with encrypted stuff.
   - throw out the password safe stuff, I don't need it.
   - exclude vulnerable ciphers from the list of supported file extensions (each supported file extension maps to a cipher type)
