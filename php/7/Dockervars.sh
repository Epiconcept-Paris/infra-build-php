#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/7

#
#	Add hooks for PHP extensions
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
#   Add PHP shared extensions
#
AddMySQL()
{
    local Tgz
    Tgz=mysql.tgz
    if [ ! -f $Dir/$Tgz ]; then
	echo "Fetching MySQL legacy extension..."
	curl -sSL "https://github.com/php/pecl-database-mysql/archive/master.tar.gz" -o $Dir/$Tgz
    fi
    EXTCOPY="$EXTCOPY
    COPY $Dir/$Tgz $BUILD_TOP/files
    COPY $Dir/mysql.sh $BUILD_TOP/hooks"
}

AddHook APCu apcu APCu apcu
AddHook oauth oauth OAuth oauth
AddMySQL
