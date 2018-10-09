#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Php=${PhpTop}$Maj

#
#   Add other files
#
AddExtra()
{
    # global Php Min BLDCOPY BUILD_TOP

    #	ereg legacy PHP extension
    #	From https://github.com/php/pecl-text-ereg
    #	Latest: https://github.com/php/pecl-text-ereg/archive/master.tar.gz
    BLDCOPY="$BLDCOPY
COPY $Php/files/ereg.tar.gz $BUILD_TOP/files
COPY $Php/hooks/ereg.sh $BUILD_TOP/hooks"

    #	MySQL legacy PHP extension
    #	From https://github.com/php/pecl-database-mysql
    #	Latest: https://github.com/php/pecl-database-mysql/archive/master.tar.gz
    BLDCOPY="$BLDCOPY
COPY $Php/files/mysql.tar.gz $BUILD_TOP/files
COPY $Php/files/mysql.patch $BUILD_TOP/files
COPY $Php/hooks/mysql.sh $BUILD_TOP/hooks"

    #	PEAR man pages
    #	From http://pear.php.net/package/PEAR_Manpages/download (see Download link)
    #	Latest: http://download.pear.php.net/package/PEAR_Manpages-1.10.0.tgz
    BLDCOPY="$BLDCOPY
COPY ${PhpTop}files/PEAR_Manpages-1.10.0.tgz $BUILD_TOP/files
COPY ${PhpTop}hooks/pearman.sh $BUILD_TOP/hooks"

    #
    #	Add libzip for 7.3+
    #
    if [ $Min -gt 2 ]; then
	BUILD_REQ="$BUILD_REQ libzip-dev"
	TESTS_REQ="$BUILD_REQ $LIBZIP"
	CLI_DEPS="$CLI_DEPS, $LIBZIP"
    fi
}

#
#   Main
#   global Php BLDCOPY BUILD_TOP BUILD_REQ TESTS_REQ CLI_DEPS LIBZIP
#
. ${PhpTop}lib/AddPECL.sh

BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

AddPECL APCu apcu APCu apcu
AddPECL oauth oauth OAuth oauth
AddPECL mcrypt mcrypt MCrypt mcrypt
AddExtra
