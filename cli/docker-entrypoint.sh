#!/bin/bash

export PHP_INI_DIR="/etc/php"

fileArkPHP=/tmp/php.tar.bz2
cheminPack=/opt/debbuild

if [ ! -f php.tar.bz2 ]; then 
	curl -SL "http://fr2.php.net/get/php-7.1.11.tar.bz2/from/this/mirror" -o $fileArkPHP
fi

rm -rf /usr/src/php
mkdir -p /usr/src/php
tar -xf $fileArkPHP -C /usr/src/php --strip-components=1
cd /usr/src/php

#--with-apxs2=/usr/bin/apxs \
#--with-apache2=/opt/debbuild/usr/lib/apache2 \

./configure	\
	--prefix=/opt/debbuild/usr \
	--with-config-file-path="$PHP_INI_DIR" \
	--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
	--with-libdir=/lib/x86_64-linux-gnu\
	--with-bz2 \
	--with-curl \
	--enable-ctype \
	--enable-ftp \
	--with-gd \
	--enable-gd-native-ttf \
	--with-jpeg-dir=/usr --with-png-dir=/usr \
	--with-freetype-dir=/usr \
	--with-xpm-dir=/usr,/usr/X11R6 \
	--with-zlib-dir=/usr \
	--with-gettext \
	--enable-json \
	--enable-oauth \
	--enable-hash \
	--with-iconv \
	--enable-libxml \
	--enable-dom \
	--enable-mbstring \
	--with-mcrypt \
	--with-mhash \
	--with-pcre-regex \
	--enable-pdo \
	--with-pdo-mysql=/usr \
	--with-mysqli=/usr/bin/mysql_config \
	--with-libdir=lib \
	--with-openssl \
	--enable-posix \
	--enable-session \
	--enable-sockets \
	--enable-sysvmsg \
	--enable-sysvsem \
	--enable-sysvshm \
	--enable-xml \
	--enable-xmlreader \
	--enable-xmlwriter \
	--with-xsl \
	--enable-simplexml \
	--enable-soap \
	--enable-wddx \
	--enable-zip \
	--with-zlib \
	--disable-debug \
	--enable-bcmath

#mkdir -p $cheminPack/etc/apache2/mods-available/

make -j"$(nproc)"
#touch /opt/debbuild/etc/apache2/mods-available/apache2.conf

make install
INSTALL_ROOT=/opt/debbuild make install

#rm /opt/debbuild/etc/apache2/mods-available/apache2.conf
make clean

bash /build_paquet.sh
