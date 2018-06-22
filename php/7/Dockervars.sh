#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/7

#
#    Add hooks for PHP extensions
#
PECLGET="http://pecl.php.net/get"
EXTCOPY="RUN mkdir $BUILD_TOP/hooks"

#   AddHook <URL-file> <Src-base> <Hook-name> <Hook-file>
AddHook()
{
    local Tgz
    Tgz=`curl -sISL "$PECLGET/$1" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
    if [ ! -f $Dir/$Tgz ]; then
	rm -f $Dir/$2-*.tgz
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "$PECLGET/$1" -o $Dir/$Tgz
    fi
    EXTCOPY="$EXTCOPY
    COPY $Dir/$Tgz $BUILD_TOP/files
    COPY $Dir/$4.sh $BUILD_TOP/hooks"
}

#
#   Add other files
#
AddExtra()
{
    local Tgz

    #	MySQL legacy PHP extension
    Tgz=mysql.tgz
    if [ ! -f $Dir/$Tgz ]; then
	echo "Fetching MySQL legacy extension..."
	curl -sSL "https://github.com/php/pecl-database-mysql/archive/master.tar.gz" -o $Dir/$Tgz
    fi
    EXTCOPY="$EXTCOPY
    COPY $Dir/$Tgz $BUILD_TOP/files
    COPY $Dir/mysql.sh $BUILD_TOP/hooks"

    #	PEAR man pages
    Tgz="PEAR_Manpages-1.10.0.tgz"
    if [ ! -f $Dir/$Tgz ]; then
	echo "Fetching PEAR manpages..."
	curl -sSL "http://download.pear.php.net/package/$Tgz" -o $Dir/$Tgz
    fi
    EXTCOPY="$EXTCOPY
    COPY $Dir/$Tgz $BUILD_TOP/files
    COPY $Dir/pearman.sh $BUILD_TOP/hooks"
}
#
#   Main
#
AddHook APCu apcu APCu apcu
AddHook oauth oauth OAuth oauth
AddExtra
