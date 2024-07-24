# Patches to PHP 5.6.40 from Debian and Freexian

Some of these patches are included in our builds because PHP 5.6 support expired with release 5.6.40 on 2018-12-31.


## Patch level `deb8u20` as of July 2024 (build 5.6.40-7)

### Source

The latest (2024-06-17) Freexian ELTS `deb8u20` patches for PHP 5.6.40 can be found on [deb.freexian.com](http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.6.40+dfsg-0+deb8u20.debian.tar.xz).

### Choice of patches

Since the previous `deb8u16` patch level below, 9 new CVE patches have been added.
They have all been selected to be included in the 5.6.40-7 build,
    but patches `CVE-2024-2756` and `CVE-2024-3096` are probably the most important security-wise.
All the `deb8u16` patches selected for the 5.6.40-6 build have othewise been retained.


## Patch level `deb8u16` as of March 2023 (build 5.6.40-6)

### Source

The latest (2020-06-28) `debian-security` `deb8u12` patches to the standard PHP 5.6.40 distribution are on [archive.debian.org](http://archive.debian.org/debian-security/pool/updates/main/p/php5/php5_5.6.40+dfsg-0+deb8u12.debian.tar.xz).

These latest Debian patches had been upgraded to `deb8u16` by Freexian on 2023-01-24 to this [new version](http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.6.40+dfsg-0+deb8u16.debian.tar.xz).

But this `deb8u16` version is no longer available as of July 2024, as it has been superseded by the `deb8u20` version.


### Choice of patches

The patches have been reviewed and only some of then have been selected and put in `deb-CVE/`
    to be included in the 5.6.40-6 build.
Patches that have not been selected fall under two categories: `unused` and `configuration`.

### Unused patches

The following patches have been discarded because they target parts of PHP that Epiconcept does not use:

```
unused/exif/CVE-2019-11034.patch
unused/exif/CVE-2019-11035.patch
unused/exif/CVE-2019-11036.patch
unused/exif/CVE-2019-11040.patch
unused/exif/CVE-2019-11041.patch
unused/exif/CVE-2019-11042.patch
unused/exif/CVE-2019-11047.patch
unused/exif/CVE-2019-11050.patch
unused/exif/CVE-2019-9638_CVE-2019-9639.patch
unused/exif/CVE-2019-9640.patch
unused/exif/CVE-2019-9641.patch
unused/exif/CVE-2020-7064.patch
unused/dba/0013-php-5.4.7-libdb.patch
unused/dba/0019-qdbm-is-usr_include_qdbm.patch
unused/dba/0030-php-5.3.3-macropen.patch
unused/firebird/0053-Add-simple-Firebird-payload-fake-server-to-test-suite.patch
unused/firebird/CVE-2021-21704.patch
unused/0006-strtod_arm_fix.patch
unused/0007-php-5.4.9-phpinfo.patch
unused/0016-sybase-alias.patch
unused/0018-dont-gitclean-in-build.patch
unused/0026-temporary-path-fixes-for-multiarch.patch
unused/0027-hurd-noptrace.patch
unused/0035-php-fpm-m68k.patch
unused/0046-Fix-ZEND_MM_ALIGNMENT-on-m64k.patch
unused/CVE-2022-31625.patch
```

### Configuration patches

The following patches have been discarded because they bring config changes that might break existing setup or use:

```
config/0001-libtool_fixes.patch
config/0003-debian_quirks.patch
config/0004-libtool2.2.patch
config/0005-we_WANT_libtool.patch
config/0008-extension_api.patch
config/0009-no_apache_installed.patch
config/0010-recode_is_shared.patch
config/0015-force_libmysqlclient_r.patch
config/0023-fpm-config.patch
config/0024-php-fpm-sysconfdir.patch
config/0031-php-5.2.4-norpath.patch
config/0033-php-5.2.4-embed.patch
config/0044-hack-phpdbg-to-explicitly-link-with-libedit.patch
```
