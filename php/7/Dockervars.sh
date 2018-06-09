#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/7

PECLURL="http://pecl.php.net/get/APCu"
Tgz=`curl -sISL "$PECLURL" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
if [ ! -f $Dir/$Tgz ]; then
    rm -f $Dir/apcu-*.tgz
    echo "Fetching APCu `expr $Tgz : 'apcu-\(.*\).tgz'` extension..."
    curl -sSL "$PECLURL" -o $Dir/$Tgz
fi
EXTCOPY="COPY $Dir/$Tgz $BUILD_TOP/files
RUN mkdir $BUILD_TOP/hooks
COPY $Dir/apcu.sh $BUILD_TOP/hooks"
