# Security patches to PHP 7.4.33 from Debian

Some of these patches are included in our builds because PHP 7.4 support expired with release 7.4.33 on 2022-11-28.


## Patch level `deb11u8` as of July 2025 (build 7.4.33-5)

### Source

The latest (2025-03-20) `debian-security` `deb11u8` patches for PHP 7.4.33 have been found on [security.debian.org](http://security.debian.org/debian-security/pool/main/p/php7.4/php7.4_7.4.33-1+deb11u8.debian.tar.xz).

### Choice of patches

Since the previous `deb11u5` patch level below, 25 new CVE patches have been added.  
Three of them are obviously of no use in Epiconcept's environment and have been discarded.  
The 22 others are all included in the 7.4.33-3 build.  
All the `deb11u3` and `deb11u5` patches selected for the 7.4.33-3 build have otherwise been retained.

### Unused patches

The following patches have been discarded because they are not useful to Epiconcept:
```
CVE-2024-11236/01-7742f79.patch		# pdo_dblib
CVE-2024-11236/02-2dbe142.patch		# pdo_firebird`
CVE-2024-8932.patch			# ldap`
```

### Sub-directories

The `debian/patches/` directory in the `deb11u5` patch-level was a flat directory, but in `deb11u8` it contains sub-directories, so the patches now come as a `deb-CVE.tgz` tarball, with a pack/unpack `mktgz` utility script.  
In addition, a `deb-CVE/series` file has been added that lists the patch files in the order they should be applied.


## Patch level `deb11u5` as of July 2024 (build 7.4.33-3)

### Source

The latest (2024-04-12) `debian-security` `deb11u5` patches for PHP 7.4.33 can be found on [ftp.debian.org](http://security.debian.org/debian-security/pool/main/p/php7.4/php7.4_7.4.33-1+deb11u5.debian.tar.xz).

### Choice of patches

Since the previous `deb11u3` patch level below, 13 new CVE patches have been added
    (of which 5 affect only the `NEWS` file).
Two of them are obviously for an MS Windows environment (`cmd.exe`) and have been discarded.
The 11 others are all included in the 7.4.33-3 build, but patches `CVE-2024-2756` and `CVE-2024-3096`
    are probably the most important security-wise.
All the `deb11u3` patches selected for the 7.4.33-2 build have otherwise been retained.

### Unused patches

The following patches have been discarded because they are useful only in an MS-Windows environment:

```
patches/0079-Add-proc_open-escaping-for-cmd-file-execution-Backpo.patch
patches/0080-NEWS.patch
```


## Patch level `deb11u3` as of March 2023 (build 7.4.33-2)

## Source

The latest (2023-02-22) `debian-security` `deb11u3` patches to the standard PHP 7.4.33 distribution were on [ftp.debian.org](http://ftp.debian.org/debian/pool/main/p/php7.4/php7.4_7.4.33-1+deb11u3.debian.tar.xz).

But this `deb11u3` version is no longer available as of July 2024, as it has been superseded by the `deb11u5` version.

### Choice of patches

The patches have been reviewed and only some of then have been selected and put in `deb-CVE/`.
Patches that have not been selected fall under two categories: `unused` and `configuration`.

### Unused patches

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

### Configuration patches

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
