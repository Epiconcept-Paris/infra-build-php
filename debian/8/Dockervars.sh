#
#	debian/8/Dockervars.sh - Define Debian packages required in Dockerfile for build and tests
#
BUILD_REQ="file curl vim build-essential autoconf pkg-config fakeroot lintian apache2 apache2-dev libmcrypt-dev libmhash-dev libjpeg-dev libxpm-dev libxslt1-dev libbz2-dev libxft-dev libmysqlclient-dev libcurl4-openssl-dev libssl-dev libpcre3-dev"
CLI_DEPS="libjpeg62-turbo, libpng12-0, libxpm4, libmcrypt4, libxslt1.1, libcurl3, libfreetype6, libmysqlclient18, libxml2, libc6"

TESTS_REQ="apache2 curl vim libjpeg62-turbo libpng12-0 libxpm4 libmcrypt4 libxslt1.1 libcurl3 libfreetype6 libmysqlclient18"
