set -e

export PHP_INI_DIR="/etc/php5/apache2"
export PHP_VERSION="5.2.17" 

set -x
if [ ! -f php.tar.bz2 ]; then
	curl -SL "http://museum.php.net/php5/php-$PHP_VERSION.tar.bz2" -o php.tar.bz2
fi

rm -rf /usr/src/php
mkdir -p /usr/src/php
tar -xf php.tar.bz2 -C /usr/src/php --strip-components=1
rm php*
cd /usr/src/php
patch -p1 < /tmp/php-5.2.17-libxml2.patch
patch -p1 < /tmp/php-5.2.17-openssl.patch
sed 's/unixd_config/ap_unixd_config/g' -i ./sapi/apache2handler/php_functions.c
sed 's/ap_unixd_config_rec/unixd_config_rec/g' -i ./sapi/apache2handler/php_functions.c

function lnlib()
{
	local src=$1
	local link=$2

	if [ ! -e "$link" ]; then 
		ln -s "$src" "$link"
	fi
}
lnlib /usr/lib/x86_64-linux-gnu/libjpeg.a /usr/lib/libjpeg.a
lnlib /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/libjpeg.so
lnlib /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib/libpng.a
lnlib /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib/libpng.so
lnlib /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib/libXpm.a

mkdir -p /usr/include/freetype2/freetype
lnlib /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h

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
	--with-ttf \
	--with-jpeg-dir=/usr --with-png-dir=/usr \
	--with-freetype-dir=/usr \
	--with-xpm-dir=shared,/usr/X11R6 \
	--with-zlib-dir=/usr \
	--with-gettext \
	--enable-json \
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
	--with-mysql \
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
	--disable-debug

sed -i 's/-lxml2 -lxml2 -lxml2/-lcrypto -lssl/' Makefile
make -j"$(nproc)"
make install
#find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true
make clean