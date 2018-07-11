#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/7

#
#    Add hooks for PECL PHP extensions
#
PECLGET="http://pecl.php.net/get"

#   AddPECL <URL-file> <Src-base> <Hook-name> <Hook-file>
AddPECL()
{
    local Tgz
    Tgz=`curl -sISL "$PECLGET/$1" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
    if [ ! -f $Dir/files/$Tgz ]; then
	rm -f $Dir/files/$2-*.tgz
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "$PECLGET/$1" -o $Dir/files/$Tgz
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
    local Tgz

    #	MySQL legacy PHP extension
    Tgz=mysql.tgz
    if [ ! -f $Dir/files/$Tgz ]; then
	echo "Fetching MySQL legacy extension..."
	curl -sSL "https://github.com/php/pecl-database-mysql/archive/master.tar.gz" -o $Dir/files/$Tgz
    fi
    BLDCOPY="$BLDCOPY
COPY $Dir/files/$Tgz $BUILD_TOP/files
COPY $Dir/files/mysql.patch $BUILD_TOP/files
COPY $Dir/hooks/mysql.sh $BUILD_TOP/hooks"

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

AddPECL APCu apcu APCu apcu
AddPECL oauth oauth OAuth oauth
AddPECL mcrypt mcrypt MCrypt mcrypt
AddExtra
