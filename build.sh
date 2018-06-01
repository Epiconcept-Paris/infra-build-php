#!/bin/sh
#
#	Make PHP packages for a given set of PHP and Debian versions
#
#	Usage:	./build.sh <PHP-version> [<Debian-version>]
#
#	PHP-version is checked to be available in PHP sources
#	Debian-version is checked to be supported and defaults to 'stretch'
#
Prg=`basename $0`
PHPSITE=fr.php.net
PHP5URL="http://museum.php.net/php5"

# Handles PHP 5.x and PHP 7.x
Versions="`curl -sSL "http://$PHPSITE/ChangeLog-5.php" "http://$PHPSITE/ChangeLog-7.php" | sed -n 's/^.*<h[1-4]>Version \([^ ]*\) *<\/h[1-4]>/\1/p' | sort -nr -t. -k 1,1 -k 2,2 -k 3,3`"
if [ -z "$Versions" ]; then
    echo "$Prg: unable to fetch the latest list of PHP versions from $PHPSITE" >&2
    exit 1
fi
Latest="`echo "$Versions" | awk -F. '{
    Mm = $1 "." $2
    if (Mm in v) {
	if (v[Mm] < $3)
	    v[Mm] = $3
    }
    else
	v[Mm] = $3
}
END {
    for (Mm in v)
	printf("%s.%s\n", Mm, v[Mm]);
}'`"
if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: ./$Prg <PHP-version> [<Debian-version]" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/	/' >&2
    echo "Supported Debian versions:" >&2
    ls debian/*/? | awk -F/ '{printf("\t%s (%s.x)\n", $2, $3)}' >&2
    exit 1
fi

split="`echo "$1" | sed -nr 's/^([57])\.([0-9]+)\.([0-9]+)$/PhpMaj=\1 PhpMin=\2 PhpSub=\3/p'`"
if [ -z "$split" ]; then
    echo "$Prg: invalid PHP version \"$1\" ([57].x.y)" >&2
    exit 1
fi
eval "$split"
if ! echo "$Versions" | grep "$1" >/dev/null; then
    echo "$Prg: unknown PHP version \"$1\"" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/	/' >&2
    exit 1
fi
PhpVer="$1"
DebVer='stretch'
if [ "$2" ]; then
    if [ -f debian/$2/Dockerfile ]; then
	DebVer="$2"
    else
	echo "$Prg: unsupported Debian version \"$2\"" >&2
	echo "Supported Debian versions:" >&2
	ls debian/*/? | awk -F/ '{printf("\t%s (%s.x)\n", $2, $3)}' >&2
	exit 1
    fi
fi
echo "DebVer=$DebVer PhpVer=$PhpVer PhpMaj=$PhpMaj PhpMin=$PhpMin PhpSub=$PhpSub"
exit 0
BUILD_TOP=/opt/build/php
BUILD_IMG=epi-build-php

docker ps | grep $BUILD_IMG >/dev/null && docker kill $BUILD_IMG
docker ps -a | grep $BUILD_IMG >/dev/null && docker rm $BUILD_IMG
docker images | grep $BUILD_IMG >/dev/null && docker rmi $BUILD_IMG
docker build -f debian/$DebVer/Dockerfile -t $BUILD_IMG --build-arg BUILD_TOP=$BUILD_TOP . >docker.out
rm -rf /tmp/$BUILD_IMG
echo "docker run -ti -v debian/$DebVer/dist:$BUILD_TOP/dist --name $BUILD_IMG --rm $BUILD_IMG bash"
