#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Php=${PhpTop}7

#
#   Add hooks for PECL PHP extensions
#
#   AddPECL <URL-file> <Src-base> <Hook-name> <Hook-file>
#
AddPECL()
{
    # global PECLGET Php Dir Prg BLDCOPY BUILD_TOP
    local Tgz Old

    Tgz=`curl -sISL "http://$PECLGET/$1" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
    if [ -z "$Tgz" ]; then
	Old=`ls $Php/files/$2-*.tgz 2>/dev/null`
	test "$Old" && Tgz=`basename $Old`
	if [ -z "$Tgz" ]; then
	    echo "Failed to download $1 extension from $PECLGET/$1" >&2
	    echo "Put it manually as $Php/files/$2-<version>.tgz and run $Dir/$Prg again" >&2
	    exit 1
	fi
    fi
    if [ ! -f $Php/files/$Tgz ]; then
	rm -vf $Php/files/$2-*.tgz | sed 's/^r/R/'	# sed for cosmetics
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "http://$PECLGET/$1" -o $Php/files/$Tgz
    fi
    BLDCOPY="$BLDCOPY
COPY $Php/files/$Tgz $BUILD_TOP/files
COPY $Php/hooks/$4.sh $BUILD_TOP/hooks"
}

#
#   Add other files
#
AddExtra()
{
    # global Php BLDCOPY BUILD_TOP

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
}

#
#   Main
#   global Php BLDCOPY BUILD_TOP
#
BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

AddPECL APCu apcu APCu apcu
AddPECL oauth oauth OAuth oauth
AddPECL mcrypt mcrypt MCrypt mcrypt
AddExtra
