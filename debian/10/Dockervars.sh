#
#	debian/10/Dockervars.sh - Define Debian packages required in Dockerfile for build and tests
#
BUILD_REQ="vim apt-rdepends file curl build-essential autoconf pkg-config faketime fakeroot lintian apache2 apache2-dev libmcrypt-dev libmhash-dev libjpeg-dev libxpm-dev libxslt1-dev libbz2-dev libxft-dev default-libmysqlclient-dev libcurl4-openssl-dev libssl-dev libpcre3-dev libsystemd-dev libsqlite3-dev libonig-dev"
CLI_DEPS="libjpeg62-turbo, libpng16-16, libxpm4, libmcrypt4, libxslt1.1, libcurl4, libfreetype6, libmariadb3, libxml2, libc6"

TESTS_REQ="vim curl apache2 libjpeg62-turbo libpng16-16 libxpm4 libmcrypt4 libxslt1.1 libcurl4 libfreetype6 libmariadb3"

LIBZIP="libzip4"