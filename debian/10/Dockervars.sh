#
#	debian/10/Dockervars.sh - Define Debian packages required in Dockerfile for build and tests
#
BUILD_REQ="vim apt-rdepends file curl build-essential autoconf pkg-config faketime fakeroot lintian apache2 apache2-dev libmcrypt-dev libmhash-dev libjpeg-dev libxpm-dev libxslt1-dev libbz2-dev libxft-dev libmariadbclient-dev libmariadb-dev-compat libcurl4-openssl-dev libssl-dev libpcre3-dev libsystemd-dev libreadline-dev"
CLI_DEPS="libjpeg62-turbo, libpng16-16, libxpm4, libmcrypt4, libxslt1.1, libcurl4, libfreetype6, libmariadb3, libxml2, libreadline7, libc6"

TESTS_REQ="vim curl apache2 libjpeg62-turbo libpng16-16 libxpm4 libmcrypt4 libxslt1.1 libcurl4 libfreetype6 libmariadb3 libreadline7"

DEV72_="libzip-dev"
LIB72_="libzip4"

DEV74_="libonig-dev libsqlite3-dev"
LIB74_="libonig5"
