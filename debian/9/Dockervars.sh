#
#	debian/9/Dockervars.sh - Define Debian packages required in Dockerfile for build and tests
#
APT_SRC="RUN sed -i -r -e 's/(deb|security)\.debian/archive.debian/' -e 's/stretch-updates/stretch-proposed-updates/' /etc/apt/sources.list"
BUILD_REQ="vim apt-rdepends file curl build-essential autoconf pkg-config faketime fakeroot lintian apache2 apache2-dev libmcrypt-dev libmhash-dev libjpeg-dev libxpm-dev libxslt1-dev libbz2-dev libxft-dev default-libmysqlclient-dev libcurl4-openssl-dev libssl-dev libpcre3-dev libsystemd-dev libreadline-dev libssh2-1-dev libc-client2007e-dev libkrb5-dev default-mysql-server"
CLI_DEPS="libjpeg62-turbo, libpng16-16, libxpm4, libmcrypt4, libxslt1.1, libcurl3, libfreetype6, libmariadbclient18, libxml2, libreadline7, libc6"

TESTS_REQ="vim curl apache2 libjpeg62-turbo libpng16-16 libxpm4 libmcrypt4 libxslt1.1 libcurl3 libfreetype6 libmariadbclient18 libreadline7 libc-client2007e"

DEV72_="libzip-dev"
LIB72_="libzip4"

DEV74_="libonig-dev libsqlite3-dev"
LIB74_="libonig4"

DEV81_="$DEV72_ $DEV74_"
LIB81_="$LIB72_ $LIB74_"
