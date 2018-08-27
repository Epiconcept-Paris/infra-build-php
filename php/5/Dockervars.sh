#
#	php/5/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Php=${PhpTop}5

#
#   Add hooks for PECL PHP extensions
#
#   AddPECL <URL-file> <Src-base> <Hook-name> <Hook-file> [<Version>]
#
AddPECL()
{
    # global PECLGET Php Dir Prg BLDCOPY BUILD_TOP
    local Tgz File Old

    if [ "$5" ]; then
	Tgz=$2-$5.tgz
	File=$Tgz
    else
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
	File=$1
    fi
    if [ ! -f $Php/files/$Tgz ]; then
	rm -vf $Php/files/$2-*.tgz | sed 's/^r/R/'	# sed for cosmetics
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "http://$PECLGET/$File" -o $Php/files/$Tgz
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
    # global Php Min BLDCOPY BUILD_TOP TSTCOPY TESTS_TOP BUILD_REQ TESTS_REQ CLI_DEPS
    local file lib off cmn

    #   Handle specific patch/package files
    if [ -d $Php/files/5.$Min ]; then
	for file in $Php/files/5.$Min/*
	do
	    # Packages (*.deb) are from http://archive.debian.org/debian/pool/main/m/mysql-dfsg-5.0
	    case $file in
		*.patch)	;;
		*-dev_*.deb)	;;
		*-common*.deb)	cmn=$file;;
		*)		off=$file; lib=`basename "$file" | awk -F_ '{print $1}'`;;
	    esac
	    BLDCOPY="$BLDCOPY
COPY $file $BUILD_TOP/files"
	done
	BLDCOPY="$BLDCOPY
COPY $Php/hooks/files.sh $BUILD_TOP/hooks"
	if [ "$cmn" -a "$off" ]; then
	    TSTCOPY="RUN mkdir $BUILD_TOP/pkgs
COPY $cmn $TESTS_TOP/pkgs
COPY $off $TESTS_TOP/pkgs"
	    BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ [^ ]*libmysqlclient-dev//'`
	    TESTS_REQ=`echo "$TESTS_REQ" | sed -r 's/ lib(mysql|mariadb)client[^ ]*//'`
	    CLI_DEPS=`echo "$CLI_DEPS"   | sed -r "s/ lib(mysql|mariadb)client[^ ]*/ $lib,/"`
	fi
    fi
    #   PHP 5.3- uses autoconf 2.13
    test $Min -le 3 && BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ autoconf/ autoconf2.13/'`

    #	PEAR man pages
    #	From http://pear.php.net/package/PEAR_Manpages/download (see Download link)
    #	Latest: http://download.pear.php.net/package/PEAR_Manpages-1.10.0.tgz
    BLDCOPY="$BLDCOPY
COPY ${PhpTop}files/PEAR_Manpages-1.10.0.tgz $BUILD_TOP/files
COPY ${PhpTop}hooks/pearman.sh $BUILD_TOP/hooks"
}

#
#   Main
#   global Php BLDCOPY BUILD_TOP Tbz PhpLst BUILD_REQ TESTS_REQ CLI_DEPS
#
BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

echo "Checking $Tbz for OpCache..."
if grep '/ext/opcache/' $PhpLst >/dev/null; then
    AddPECL APCu apcu APCu apcu 4.0.11	# Last version to support PHP5
else
    AddPECL APC APC APC apc
fi
if ! grep '/ext/fileinfo/' $PhpLst >/dev/null; then
    AddPECL Fileinfo Fileinfo FileInfo fileinfo
    BUILD_REQ="$BUILD_REQ libmagic-dev"
    TESTS_REQ="$TESTS_REQ libmagic1"
    CLI_DEPS="$CLI_DEPS, libmagic1"
fi
AddPECL oauth oauth OAuth oauth 1.2.3	# Last version to support PHP5
AddExtra
