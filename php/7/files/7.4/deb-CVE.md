# Patches to PHP 7.4.33 from debian as of March 2023

## Source
The latest debian-security patches to the standard PHP 7.4.33 distribution are on [ftp.debian.org](http://ftp.debian.org/debian/pool/main/p/php7.4/php7.4_7.4.33-1+deb11u3.debian.tar.xz) (2023-02-22).

## Choice of patches

The patches have been reviewed and only some of then have been selected and put in `deb/`.

## Unused patches

The following patches have been discarded because they target parts of PHP that Epiconcept does not use:

```
unused/dba/0007-php-5.4.7-libdb.patch
unused/dba/0010-qdbm-is-usr_include_qdbm.patch
unused/dba/0020-php-5.3.3-macropen.patch
unused/0003-php-5.4.9-phpinfo.patch
unused/0016-temporary-path-fixes-for-multiarch.patch
unused/0017-hurd-noptrace.patch
unused/0022-php-fpm-m68k.patch
unused/0032-Fix-ZEND_MM_ALIGNMENT-on-m64k.patch
unused/0040-remove-deprecated-call-and-deprecate-function-to-be-.patch
unused/0041-Use-libenchant-2-when-available.patch
unused/0045-Don-t-use-hrtimers-on-GNU-Hurd.patch
unused/0050-Fix-GH-10187-Segfault-in-stripslashes-with-arm64.patch
```

## Configuration patches

The following patches have been discarded because they bring config changes that might break existing setup or use:

```
config/0001-libtool_fixes.patch
config/0002-debian_quirks.patch
config/0004-extension_api.patch
config/0013-fpm-config.patch
config/0014-php-fpm-sysconfdir.patch
config/0021-php-5.2.4-embed.patch
config/0023-expose_all_built_and_installed_apis.patch
config/0027-php-5.4.8-ldap_r.patch
config/0031-hack-phpdbg-to-explicitly-link-with-libedit.patch
config/0033-Add-patch-to-install-php7-module-directly-to-APXS_LI.patch
config/0035-Don-t-put-INSTALL_ROOT-into-phar.phar-exec-stanza.patch
config/0036-XMLRPC-EPI-library-has-to-be-linked-as-lxmlrpc-epi.patch
config/0037-Really-expand-libdir-datadir-into-EXPANDED_LIBDIR-DA.patch
config/0039-Amend-C-11-for-intl-compilation-on-older-distributio.patch
config/0042-libtool2.2.patch
config/0043-Include-all-libtool-files-from-phpize.m4.patch
config/0044-In-phpize-also-copy-config.guess-config.sub-ltmain.s.patch
```

Among these, the `0023-expose_all_built_and_installed_apis.patch` and `0027-php-5.4.8-ldap_r.patch` were initially selected but are discarded in the end as they are rejected.
