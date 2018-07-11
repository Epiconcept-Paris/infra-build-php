## Infos pratiques

* __IP serveur AWS de build : 34.243.220.28 (compte "cdt")__
* x source pour le build PHP5.2, utilisateur "cdt", url Subversion : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/ (le but n'est vraiment pas d'intégrer directement, mais de reprendre les éléments et de les intégrer)
* x le script actuel de build est dans mod/docker-entrypoint.sh
* x doc d'utilisation ci-dessous

# Notes

Lancement du build paquet :

```console
* x docker kill epi-build-php71; \
* x docker rm epi-build-php71; \
* x docker rmi --force epi-build-php71 &>/dev/null; \
* x docker-compose up --force-recreate`
```

* paquet à trouver dans `/tmp/epi-build-php71`

Pour la mise au point --with-apache2:
```console
* x docker-compose build
* x docker run -ti -v /tmp/epi-build-php71:/opt/output epi-build-php71 bash
* x bash -x /docker-entrypoint.sh
* x bash -x /build_paquet.sh
```

Pour la mise au point --no-apache2:

```console
* x docker-compose build
* x docker run -ti -v /tmp/epi-php-cli-7-1:/opt/output epi-php-cli-7-1 bash
* x bash -x /docker-entrypoint.sh
* x bash -x /build_paquet.sh
```

## Plan simple pour tester le paquet

`docker run -ti debian:stretch --name testdeb --rm bash`

```console
* x apt update
* x apt install -y apache2 vim nano
* x a2dismod mpm_event && a2enmod mpm_prefork && service apache2 restart
* x dpkg -i epi-php-7-1_7.1.11_amd64.deb ; apt-get -yf install ; service apache2 restart
```

## Docs

* [Building PHP](http://www.phpinternalsbook.com/build_system/building_php.html)
* [Installing PHP in my HOME directory](https://stackoverflow.com/questions/19247529/installing-php-in-my-home-directory)

## Microplan

* x finir le build
* __déployer sur prephp7a1 et tester__
* __déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)__

# TODO

## Build paquet

```console
x E: epi-php-7-1: unstripped-binary-or-object bin/php
x E: epi-php-7-1: binary-or-shlib-defines-rpath bin/php /usr/lib/x86_64-linux-gnu
x E: epi-php-7-1: embedded-library bin/php: libgd
x E: epi-php-7-1: embedded-library bin/php: file
x E: epi-php-7-1: unstripped-binary-or-object bin/php-cgi
x E: epi-php-7-1: binary-or-shlib-defines-rpath bin/php-cgi /usr/lib/x86_64-linux-gnu
x E: epi-php-7-1: embedded-library bin/php-cgi: libgd
~ E: epi-php-7-1: embedded-library ... use --no-tag-display-limit to see all (or pipe to a file/program)
x E: epi-php-7-1: unstripped-binary-or-object bin/phpdbg
x E: epi-php-7-1: binary-or-shlib-defines-rpath bin/phpdbg /usr/lib/x86_64-linux-gnu
~ E: epi-php-7-1: unstripped-binary-or-object ... use --no-tag-display-limit to see all (or pipe to a file/program)
x W: epi-php-7-1: missing-depends-line
x E: epi-php-7-1: changelog-file-missing-in-native-package
x E: epi-php-7-1: file-in-etc-not-marked-as-conffile etc/apache2/mods-available/php7.conf
x E: epi-php-7-1: file-in-etc-not-marked-as-conffile etc/pear.conf
x E: epi-php-7-1: no-copyright-file
x E: epi-php-7-1: extended-description-is-empty
x E: epi-php-7-1: non-standard-toplevel-dir include/
x W: epi-php-7-1: file-in-unusual-dir include/php/TSRM/TSRM.h
x W: epi-php-7-1: file-in-unusual-dir include/php/TSRM/readdir.h
x W: epi-php-7-1: file-in-unusual-dir include/php/TSRM/tsrm_config.h
~ W: epi-php-7-1: file-in-unusual-dir ... use --no-tag-display-limit to see all (or pipe to a file/program)
x W: epi-php-7-1: extra-license-file lib/php/doc/PEAR/LICENSE
x W: epi-php-7-1: extra-license-file lib/php/doc/Structures_Graph/LICENSE
x E: epi-php-7-1: non-standard-toplevel-dir php/
x W: epi-php-7-1: binary-without-manpage bin/pear
x W: epi-php-7-1: binary-without-manpage bin/peardev
x W: epi-php-7-1: binary-without-manpage bin/pecl
~ W: epi-php-7-1: binary-without-manpage ... use --no-tag-display-limit to see all (or pipe to a file/program)
x W: epi-php-7-1: script-not-executable bin/pear
x W: epi-php-7-1: script-not-executable bin/peardev
x W: epi-php-7-1: script-not-executable bin/pecl
~ W: epi-php-7-1: script-not-executable ... use --no-tag-display-limit to see all (or pipe to a file/program)
x E: epi-php-7-1: wrong-path-for-interpreter bin/phar.phar (#!/opt/debbuild/bin/php != /usr/bin/php)
x W: epi-php-7-1: maintainer-script-empty postrm
```

## Améliorations

* x transformer le container dédié 7.1 à un container de build générique (5.2, 7.1, 7.2 and so on)
* __voir si on peut optimiser la phase de build en fonction du nombre de cores CPU__
* __voir s'il faut builder pour autre chose que amd64 (arm par ex)__

```console
x Configuring SAPI modules
x checking for Apache 2.0 handler-module support via DSO through APXS... [Thu Nov 23 16:51:39.629000 2017] [core:warn] [pid 1577] AH00111: Config variable ${APACHE_RUN_DIR} is not defined
x apache2: Syntax error on line 80 of /etc/apache2/apache2.conf: DefaultRuntimeDir must be a valid directory, absolute or relative to ServerRoot


~ Installing PHP SAPI module:       apache2handler
~ /usr/share/apache2/build/instdso.sh SH_LIBTOOL='/usr/share/apr-1.0/build/libtool' libphp7.la /usr/lib/apache2/modules
~ /usr/share/apr-1.0/build/libtool --mode=install install libphp7.la /usr/lib/apache2/modules/
~ libtool: install: install .libs/libphp7.so /usr/lib/apache2/modules/libphp7.so
~ libtool: install: install .libs/libphp7.lai /usr/lib/apache2/modules/libphp7.la
~ libtool: warning: remember to run 'libtool --finish /usr/src/php/libs'
~ chmod 644 /usr/lib/apache2/modules/libphp7.so


x /usr/share/apache2/build/instdso.sh SH_LIBTOOL='/usr/share/apr-1.0/build/libtool' libphp7.la /opt/debbuild//usr/lib/apache2/modules
x /usr/share/apr-1.0/build/libtool --mode=install install libphp7.la /opt/debbuild//usr/lib/apache2/modules/
x libtool: install: install .libs/libphp7.so /opt/debbuild//usr/lib/apache2/modules/libphp7.so
x libtool: install: install .libs/libphp7.lai /opt/debbuild//usr/lib/apache2/modules/libphp7.la
x libtool: warning: remember to run 'libtool --finish /usr/src/php/libs'
x chmod 644 /opt/debbuild//usr/lib/apache2/modules/libphp7.so
x apxs:Error: Config file /opt/debbuild//etc/apache2/mods-available not found.
x Makefile:162: recipe for target 'install-sapi' failed
```

```console
x root@17eecc661e56:/usr/src/php# INSTALL_ROOT=/opt/debbuild make install
x Installing PHP SAPI module:       apache2handler
x /usr/share/apache2/build/instdso.sh SH_LIBTOOL='/usr/share/apr-1.0/build/libtool' libphp7.la /opt/debbuild/usr/lib/apache2/modules
x /usr/share/apr-1.0/build/libtool --mode=install install libphp7.la /opt/debbuild/usr/lib/apache2/modules/
x libtool: install: install .libs/libphp7.so /opt/debbuild/usr/lib/apache2/modules/libphp7.so
x libtool: install: install .libs/libphp7.lai /opt/debbuild/usr/lib/apache2/modules/libphp7.la
x libtool: warning: remember to run 'libtool --finish /usr/src/php/libs'
x chmod 644 /opt/debbuild/usr/lib/apache2/modules/libphp7.so
x [preparing module `php7' in /opt/debbuild/etc/apache2/mods-available/php7.load]
x ERROR: Module php7 does not exist!
x 'a2enmod php7' failed
x Makefile:162: recipe for target 'install-sapi' failed
x make: *** [install-sapi] Error 25
```

NON [CdT] ! ==>> make install suivi du make install dans le dossier du paquet
```console
x libtool: link: `Zend/zend_execute.lo' is not a valid libtool object
x Makefile:285: recipe for target 'sapi/cli/php' failed
x make[1]: *** [sapi/cli/php] Error 1
x Makefile:465: recipe for target 'install-pear' failed
x make: *** [install-pear] Error 2
```

x Cf Supra [CdT] ==>> besoin de tout relancer (configure/make) avant le make install ? ou alors -j4 qui lance les builds dans le mauvais ordre pour le make install ?

pour le build
* x chmod des binaires

pour le clean
* x warning dans le make install
