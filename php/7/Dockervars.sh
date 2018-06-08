#
#	php/7/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Dir=php/7

echo "Fetching APCu extension..."
PECLURL="http://pecl.php.net/get/APCu"
rm -f $Dir/apcu-*.tgz
Tgz=`curl -sISL "$PECLURL" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
curl -sSL "$PECLURL" -o $Dir/$Tgz

EXTCOPY="COPY $Dir/$Tgz $BUILD_TOP/files
RUN mkdir $BUILD_TOP/hooks
COPY $Dir/apcu.sh $BUILD_TOP/hooks"
