export PHP_INI_DIR="/etc/php7/apache2"

if [ ! -f php.tar.bz2 ]; then 
	curl -SL "http://fr2.php.net/get/php-7.1.11.tar.bz2/from/this/mirror" -o /opt/php-to-build/php.tar.bz2 
fi

rm -rf /usr/src/php
mkdir -p /usr/src/php
tar -xf php.tar.bz2 -C /usr/src/php --strip-components=1
rm php*
cd /usr/src/php

./configure	\
	--prefix=/usr \
	--with-config-file-path="$PHP_INI_DIR" \
	--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
	--with-libdir=/lib/x86_64-linux-gnu\
	--with-apxs2=/usr/bin/apxs \
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

make -j"$(nproc)"
make install
make clean