#
#	php/5/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/5

#
#    Add hooks for PECL PHP extensions
#
PECLGET="http://pecl.php.net/get"

#   AddPECL <URL-file> <Src-base> <Hook-name> <Hook-file> <Version>
AddPECL()
{
    local Tgz File
    if [ "$5" ]; then
	Tgz=$2-$5.tgz
	File=$Tgz
    else
	Tgz=`curl -sISL "$PECLGET/$1" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
	File=$1
    fi
    if [ ! -f $Dir/files/$Tgz ]; then
	rm -vf $Dir/files/$2-*.tgz | sed 's/^r/R/'	# sed for cosmetics
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "$PECLGET/$File" -o $Dir/files/$Tgz
    fi
    BLDCOPY="$BLDCOPY
COPY $Dir/files/$Tgz $BUILD_TOP/files
COPY $Dir/hooks/$4.sh $BUILD_TOP/hooks"
}

#
#   Add other files
#
AddExtra()
{
    local file lib off cmn

    #   For PHP 5.2-
    if [ $Min -le 2 ]; then
	# Packages (*.deb) are from http://archive.debian.org/debian/pool/main/m/mysql-dfsg-5.0
	for file in $Dir/files/*.deb $Dir/files/*.patch
	do
	    case $file in
		*.patch) ;;
		*-dev_*.deb) ;;
		*-common*.deb) cmn=$file;;
		*) off=$file; lib=`basename "$file" | awk -F_ '{print $1}'`;;
	    esac
	    BLDCOPY="$BLDCOPY
COPY $file $BUILD_TOP/files"
	done
	BLDCOPY="$BLDCOPY
COPY $Dir/hooks/files.sh $BUILD_TOP/hooks"
	TSTCOPY="RUN mkdir $BUILD_TOP/pkgs
COPY $cmn $TESTS_TOP/pkgs
COPY $off $TESTS_TOP/pkgs"
	BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ [^ ]*libmysqlclient-dev//'`
	TESTS_REQ=`echo "$TESTS_REQ" | sed -r 's/ lib(mysql|mariadb)client[^ ]*//'`
	CLI_DEPS=`echo "$CLI_DEPS"   | sed -r "s/ lib(mysql|mariadb)client[^ ]*/ $lib,/"`
    fi
    #   PHP 5.3- uses autoconf 2.13
    test $Min -le 3 && BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ autoconf/ autoconf2.13/'`

    #	PEAR man pages
    Tgz="PEAR_Manpages-1.10.0.tgz"
    if [ ! -f $Dir/files/$Tgz ]; then
	echo "Fetching PEAR manpages..."
	curl -sSL "http://download.pear.php.net/package/$Tgz" -o $Dir/files/$Tgz
    fi
    BLDCOPY="$BLDCOPY
COPY $Dir/files/$Tgz $BUILD_TOP/files
COPY $Dir/hooks/pearman.sh $BUILD_TOP/hooks"
}

#
#   Main
#
BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

echo "Checking $PhpSrc for OpCache..."
if tar tf $PhpDir/$PhpSrc | grep '/ext/opcache/' >/dev/null; then
    AddPECL APCu apcu APCu apcu 4.0.11	# Last version to support PHP5
else
    AddPECL APC APC APC apc
fi
AddExtra
