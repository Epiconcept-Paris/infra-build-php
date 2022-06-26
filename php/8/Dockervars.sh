#
#	php/8/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Php=${PhpTop}$Maj

#
#   Add other files
#
AddExtra()
{
    # global Php Min BLDCOPY BUILD_TOP

    #	MySQL legacy PHP extension
    #	From https://github.com/php/pecl-database-mysql
    #	Latest: https://github.com/php/pecl-database-mysql/archive/master.tar.gz
    BLDCOPY="$BLDCOPY
COPY $Php/files/mysql.tar.gz $BUILD_TOP/files
COPY $Php/files/mysql.patch $BUILD_TOP/files
COPY $Php/files/mysqlnd.patch $BUILD_TOP/files
COPY $Php/hooks/mysql.sh $BUILD_TOP/hooks"

    #	PEAR man pages
    #	From http://pear.php.net/package/PEAR_Manpages/download (see Download link)
    #	Latest: http://download.pear.php.net/package/PEAR_Manpages-1.10.0.tgz
    BLDCOPY="$BLDCOPY
COPY ${PhpTop}files/PEAR_Manpages-1.10.0.tgz $BUILD_TOP/files
COPY ${PhpTop}hooks/pearman.sh $BUILD_TOP/hooks"

    #
    #	Add specific dev and lib packages
    #
    BUILD_REQ="$BUILD_REQ $DEV81_"
    TESTS_REQ="$BUILD_REQ $LIB81_"
    CLI_DEPS="$CLI_DEPS, $(echo "$LIB81_" | sed 's/ /, /g')"

    #	Add patches for Debian 10+
    if [ $DebNum -gt 9 ]; then
	BUILD_REQ="ed $BUILD_REQ"
	BLDCOPY="$BLDCOPY
COPY ${PhpTop}hooks/mysqli.sh $BUILD_TOP/hooks"
    fi
}

#
#   Main
#   global Php BLDCOPY BUILD_TOP BUILD_REQ TESTS_REQ CLI_DEPS DEV7?_ LIB7?_
#
. ${PhpTop}lib/AddPECL.sh

BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

AddPECL APCu apcu APCu apcu
#AddPECL APCu_bc apcu_bc APCu_bc apcu_bc
AddPECL oauth oauth OAuth oauth
AddPECL mcrypt mcrypt MCrypt mcrypt
AddPECL ssh2 ssh2 SSH2 ssh2
AddExtra
