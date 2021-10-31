# VIMCRYPT vim plugin - encrypt your files with openssl

This code has been derived from [openssl.vim](https://github.com/vim-scripts/openssl.vim) 

(There is a second version of this plugin, please check out [vimcrypt2](https://github.com/MoserMichael/vimcrypt2) )

It will you openssl to encrypt/decryt any text file with the following extensions:  ``` *.aes,*.cast,*.rc5,*.desx ```

It prompts you for a password while reading and writing these files.

My changes on top of openssl.vim:

   - use aes-256-ecb instead of aes-256-cbc. Reason: if the file gets damaged, then all the data after the damage point is lost, when using cipher block chaining (cbc). The damage would be limited to the AES block with the damaged byte, when using ecb.
   - turn off vim options ```shelltemp``` and ```undofile``` when working with encrypted stuff.
   - exclude vulnerable ciphers from the list of supported file extensions (each supported file extension maps to a cipher type)
   - before encrypting an existing file: back up the old file. The new encryption will prompt for a password, so that you still have the old version, in the event that you have mistyped the pasword.
   - throw out the password safe stuff, I don't need it.

# Possible issues

### multiple versions of openssl

On OSX you do have openssl installed by default, however they use the LibreSSL fork 

```
$ which openssl
/usr/bin/openssl

$ openssl version
LibreSSL 2.8.3
```

Now you can install openssl with brew, this gives you a real openssl

```
$ brew install openssl

$ /usr/local/opt/openssl/bin/openssl version
OpenSSL 3.0.0 7 sep 2021 (Library: OpenSSL 3.0.0 7 sep 2021)
```

Now the interesting detail: the output of these two utilities can't be mixed.

The following command encrypts and decrypts a string with the same password, while using the same version of openssl


```
echo '123' | /usr/bin/openssl enc -e -aes-256-ecb -pass pass:blabla | /usr/bin/openssl enc -d -aes-256-ecb -pass pass:blabla
123

echo '123' | /usr/local/opt/openssl/bin/openssl enc -e -aes-256-ecb -pass pass:blabla | /usr/local/opt/openssl/bin/openssl enc -d -aes-256-ecb -pass pass:blabla
123

```

However the same does not work, if you  try to decrypt the output of the libre ssl fork with a different utility from OpenSSL.

```
echo '123' | /usr/local/opt/openssl/bin/openssl enc -e -aes-256-ecb -pass pass:blabla | /usr/bin/openssl enc -d -aes-256-ecb -pass pass:blabla
<error error error>

echo '123' | /usr/bin/openssl enc -e -aes-256-ecb -pass pass:blabla | /usr/local/opt/openssl/bin/openssl enc -d -aes-256-ecb -pass pass:blabla
<error error error>

```

This is something that should be remembered, when moving encrypted files between different locations.


# Acknowledgement

This plugin is based on openssl.vim by Noah Spurrier [link](https://github.com/vim-scripts/openssl.vim)


