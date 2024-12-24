# VIMCREEPT - Enhanced encryption plugin for Vim
This is a fork of [vimcrypt](https://github.com/MoserMichael/vimcrypt), which was derived from [openssl.vim](https://github.com/vim-scripts/openssl.vim).

It uses openssl to encrypt/decrypt text files with the following extensions: `*.aes,*.cast,*.rc5,*.desx`
The plugin prompts for a password while reading and writing these files.

## Changes from vimcrypt
- Reverted back to aes-256-cbc from aes-256-ecb for better security
- Added session-based password memory feature
  - Remembered passwords are stored only in script scope
  - Previously entered passwords are shown as default values in the prompt
  - Passwords are cleared from memory when vim session ends
- Improved gvim compatibility by using vim's native input function
- Retained all security features from vimcrypt:
  - Disabled `shelltemp` and `undofile` for encrypted files
  - Excluded vulnerable ciphers
  - Automatic backup before encryption
  - Password confirmation when encrypting


## Original features from vimcrypt

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
echo '123' | /usr/bin/openssl enc -e -aes-256-cbc -pbkdf2 -pass pass:blabla | /usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:blabla
123

echo '123' | /usr/local/opt/openssl/bin/openssl enc -e -aes-256-cbc -pbkdf2 -pass pass:blabla | /usr/local/opt/openssl/bin/openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:blabla
123

```

However the same does not work, if you try to decrypt the output of the libre ssl fork with a different utility from OpenSSL.

```
echo '123' | /usr/local/opt/openssl/bin/openssl enc -e -aes-256-cbc -pbkdf2 -pass pass:blabla | /usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:blabla
<error error error>

echo '123' | /usr/bin/openssl enc -e -aes-256-cbc -pbkdf2 -pass pass:blabla | /usr/local/opt/openssl/bin/openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:blabla
<error error error>

```

This is something that should be remembered, when moving encrypted files between different locations.


## Acknowledgements
This plugin is based on:
- [vimcrypt](https://github.com/MoserMichael/vimcrypt) by MoserMichael
- [openssl.vim](https://github.com/vim-scripts/openssl.vim) by Noah Spurrier


