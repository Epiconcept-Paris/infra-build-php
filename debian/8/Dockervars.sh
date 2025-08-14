#
#	debian/8/Dockervars.sh - Define Debian packages required in Dockerfile for build and tests
#
APT_SRC="RUN sed -ri -e 's/^deb /deb [trusted=yes] /' -e 's/(deb|security)\.debian/archive.debian/' -e '/ jessie-updates /d' /etc/apt/sources.list"
BUILD_REQ="vim apt-rdepends file curl build-essential autoconf pkg-config faketime fakeroot lintian apache2 apache2-dev libmcrypt-dev libmhash-dev libjpeg-dev libxpm-dev libxslt1-dev libbz2-dev libxft-dev libmysqlclient-dev libcurl4-openssl-dev libssl-dev libpcre3-dev libsystemd-dev libreadline-dev libssh2-1-dev libicu-dev libc-client2007e-dev libkrb5-dev mysql-server"
CLI_DEPS="libjpeg62-turbo, libpng12-0, libxpm4, libmcrypt4, libxslt1.1, libcurl3, libfreetype6, libmysqlclient18, libxml2, libreadline6, libicu52, libc6"

TESTS_REQ="vim curl apache2 libjpeg62-turbo libpng12-0 libxpm4 libmcrypt4 libmhash2 libxslt1.1 libcurl3 libfreetype6 libmysqlclient18 libreadline6 libicu52 libc-client2007e"

DEV72_="libzip-dev"
LIB72_="libzip2"

DEV74_="libonig-dev libsqlite3-dev"
LIB74_="libonig2"

DEV81_="$DEV72_ $DEV74_"
LIB81_="$LIB72_ $LIB74_"
