#!/bin/sh
#
#	Make PHP packages for a given set of PHP and Debian versions
#
#	Usage:	./build.sh <PHP-version> [<Debian-version>]
#
#	PHP-version is checked to be available in PHP sources
#	Debian-version is checked to be supported and defaults to 'stretch'
#
PHPSITE='fr.php.net'
PHP5URL="http://museum.php.net/php5"
#
Prg=`basename $0`
Dir=`dirname $0`
#
# Get existing PHP 5.x and 7.x versions
#
Versions="`curl -sSL "http://$PHPSITE/ChangeLog-5.php" "http://$PHPSITE/ChangeLog-7.php" | sed -n 's/^.*<h[1-4]>Version \([^ ]*\) *<\/h[1-4]>/\1/p' | sort -nr -t. -k 1,1 -k 2,2 -k 3,3`"
if [ -z "$Versions" ]; then
    echo "$Prg: unable to fetch the latest list of PHP versions from \"$PHPSITE\"" >&2
    exit 1
fi
#
# From $Versions isolate latest sub for each Maj.min
#
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
#
#   Check usage
#
test "$Dir" = '.' || cd "$Dir"
if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: ./$Prg <PHP-version> [ <Debian-version> ]" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/    /' >&2
    echo "Supported Debian versions:" >&2
    ls debian | sort -n | while read v; do printf "    %2d (`cat debian/$v/name`)\n" $v; done
    exit 1
fi

#
#   Check PHP version
#
split="`echo "$1" | sed -nr 's/^([57])\.([0-9]+)\.([0-9]+)$/PhpMaj=\1 PhpMin=\2 PhpSub=\3/p'`"
if [ -z "$split" ]; then
    echo "$Prg: invalid PHP version \"$1\" ([57].x.y)" >&2
    exit 1
fi
eval "$split"
if ! echo "$Versions" | grep "$1" >/dev/null; then
    echo "$Prg: unknown PHP version \"$1\"" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/    /' >&2
    exit 1
fi
PhpVer="$1"
#
#   Check Debian version
#
if [ "$2" ]; then
    DebNum="$2"
    if [ ! -f debian/$2/name ]; then
	echo "$Prg: unsupported Debian version \"$2\"" >&2
	echo "Supported Debian versions:" >&2
	ls debian | sort -n | while read v; do printf "    %2d (`cat debian/$v/name`)\n" $v; done
	exit 1
    fi
else
    DebNum=`ls debian | sort -n | tail -1`
fi
DebVer="`cat debian/$DebNum/name`"
#echo "DebVer=$DebVer PhpVer=$PhpVer PhpMaj=$PhpMaj PhpMin=$PhpMin PhpSub=$PhpSub"
#
#   Fetch PHP source
#
PhpDir=php/$PhpMaj/$PhpVer 
DebDir=debian/$DebNum
test -d $PhpDir || mkdir $PhpDir
test -d $DebDir || mkdir $DebDir
PhpSrc=php-$PhpVer.tar.bz2
if [ ! -f $PhpDir/$PhpSrc ]; then
    echo "Fetching $PhpSrc..."
    curl -sSL "http://$PHPSITE/get/$PhpSrc/from/this/mirror" -o $PhpDir/$PhpSrc
fi
#
#   Build image and start container
#
BUILD_TOP=/opt/build
BUILD_IMG=epi-build-php
. $DebDir/Dockervars.sh
. php/$PhpMaj/Dockervars.sh

if docker ps | grep $BUILD_IMG >/dev/null; then
    echo "Stopping running '$BUILD_IMG' container..."
    docker stop $BUILD_IMG >/dev/null
fi
if docker ps -a | grep $BUILD_IMG >/dev/null; then
    echo "Deleting existing '$BUILD_IMG' container..."
    docker rm $BUILD_IMG >/dev/null
fi
if docker images | grep $BUILD_IMG >/dev/null; then
    echo "Deleting existing '$BUILD_IMG' image..."
    docker rmi $BUILD_IMG >/dev/null
fi
echo "Building '$BUILD_IMG' image..."
DEBVER="$DebVer" BUILD_REQ="$BUILD_REQ" PHPSRC="$PhpDir/$PhpSrc" EXTCOPY="$EXTCOPY" BUILD_TOP="$BUILD_TOP" PHPVER="$PhpVer" envsubst '$DEBVER $BUILD_REQ $PHPSRC $EXTCOPY $BUILD_TOP $PHPVER' <Dockerfile.in | tee tmp/Dockerfile | docker build -f - -t $BUILD_IMG . >tmp/docker-build.out 2>&1

echo "Running '$BUILD_IMG' container..."
Cmd="docker run -ti -v `pwd`/$DebDir/dist:$BUILD_TOP/dist --name $BUILD_IMG --rm $BUILD_IMG"
$Cmd
test -f pkgs/.norun && echo "Use:\n    $Cmd bash\nto run the container again"
