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
    local dir file mk

    #   Handle specific patch files
    dir="$Php/files/$Maj.$Min"
    if [ -d $dir ]; then
	mk=
	for file in $dir/deb-CVE/*.patch
	do
	    test -f "$file" || continue	# *.patch pattern may not match
	    test "$mk" || {
		BLDCOPY="$BLDCOPY
RUN mkdir $BUILD_TOP/files/deb"
		mk=y
	    }
	    BLDCOPY="$BLDCOPY
COPY $file $BUILD_TOP/files/deb"
	done
	test "$mk" && BLDCOPY="$BLDCOPY
COPY $Php/hooks/files.sh $BUILD_TOP/hooks"
    fi

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

    #	OpenSSL PHP extension (RSA_SSLV23_PADDING not #defined)
    BLDCOPY="$BLDCOPY
COPY $Php/files/openssl.patch $BUILD_TOP/files
COPY $Php/hooks/openssl.sh $BUILD_TOP/hooks"

    #	PEAR man pages
    #	From http://pear.php.net/package/PEAR_Manpages/download (see Download link)
    #	Latest: http://download.pear.php.net/package/PEAR_Manpages-1.10.0.tgz
    BLDCOPY="$BLDCOPY
COPY ${PhpTop}files/PEAR_Manpages-1.10.0.tgz $BUILD_TOP/files
COPY ${PhpTop}hooks/pearman.sh $BUILD_TOP/hooks"

    #
    #	For 7.2+, add specific dev and lib packages
    #
    if [ $Min -ge 2 ]; then
	BUILD_REQ="$BUILD_REQ $DEV72_"
	TESTS_REQ="$TESTS_REQ $LIB72_"
	CLI_DEPS="$CLI_DEPS, $(echo "$LIB72_" | sed 's/ /, /g')"
    fi

    #
    #	For 7.4+, add specific dev and lib packages..
    #
    if [ $Min -ge 4 ]; then
	BUILD_REQ="$BUILD_REQ $DEV74_"
	TESTS_REQ="$TESTS_REQ $LIB74_"
	CLI_DEPS="$CLI_DEPS, $(echo "$LIB74_" | sed 's/ /, /g')"

	#   ..and the wddx legacy PHP extension
	#   From https://github.com/php/pecl-text-wddx
	#   Latest: https://github.com/php/pecl-text-wddx/archive/master.tar.gz
	BLDCOPY="$BLDCOPY
COPY $Php/files/wddx.tar.gz $BUILD_TOP/files
COPY $Php/hooks/wddx.sh $BUILD_TOP/hooks"
    fi

    #	Add patch for Debian 9+
    if [ $DebNum -ge 9 ]; then
	BLDCOPY="$BLDCOPY
COPY ${PhpTop}hooks/mysqli.sh $BUILD_TOP/hooks"
    fi

    #	Add package and possible patch for Debian 10+
    if [ $DebNum -ge 10 ]; then
	BUILD_REQ="ed $BUILD_REQ"	# For php/pkgs/00-cli/install
	# 7.4 seems to not need this patch
	if [ $Min -lt 4 ]; then
	    BLDCOPY="$BLDCOPY
COPY ${PhpTop}hooks/freetype.sh $BUILD_TOP/hooks"
	fi
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
AddPECL ssh2 ssh2 SSH2 ssh2 1.3.1
AddExtra
