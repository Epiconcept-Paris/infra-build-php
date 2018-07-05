#!/bin/sh
#
#	Make PHP packages for a given set of PHP and Debian versions
#
#	Usage:	./mk.sh <PHP-version> [<Debian-version>]
#
#	PHP-version is checked to be available in PHP sources on $PHPSITE
#	Debian-version is checked to be supported and defaults to latest version
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
    echo "$Prg: unable to fetch the latest lists of PHP versions from \"$PHPSITE\"" >&2
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
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
DebNum=`ls debian | sort -n | tail -1`	# Default = latest
if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $Dir/$Prg <PHP-version> [ <Debian-version> ]" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/    /' >&2
    echo "Supported Debian versions (default $DebNum):" >&2
    ls debian | sort -n | while read v; do test -f debian/$v/name && printf "    %2d (`cat debian/$v/name`)\n" $v; done >&2
    exit 1
fi

#
#   Check PHP version
#
split="`echo "$1" | sed -nr 's/^([57])\.([0-9]+)\.([0-9]+)$/Maj=\1 Min=\2 Sub=\3/p'`"
if [ -z "$split" ]; then
    echo "$Prg: invalid PHP version \"$1\" ([57].x.y)" >&2
    exit 1
fi
eval "$split"
if echo "$Versions" | grep "^$Maj\.$Min\.$Sub$" >/dev/null; then
    PhpVer="$1"
    PhpDir=php/$Maj/$PhpVer
else
    echo "$Prg: unknown PHP version \"$1\"" >&2
    echo "Latest PHP 5/7 versions:" >&2
    echo "$Latest" | sed 's/^/    /' >&2
    exit 1
fi
#
#   Check Debian version
#
if [ "$2" ]; then
    if [ -f debian/$2/name ]; then
	DebNum="$2"
    else
	echo "$Prg: unsupported Debian version \"$2\"" >&2
	echo "Supported Debian versions (default $DebNum):" >&2
	ls debian | sort -n | while read v; do test -f debian/$v/name && printf "    %2d (`cat debian/$v/name`)\n" $v; done >&2
	exit 1
    fi
fi
DebVer="`cat debian/$DebNum/name`"
DebDir=debian/$DebNum
#echo "DebVer=$DebVer PhpVer=$PhpVer Maj=$Maj Min=$Min Sub=$Sub"

#
#   Fetch PHP source
#
date '+===== %Y-%m-%d %H:%M:%S %Z'
Now=`date '+%s'`
test -d $PhpDir || mkdir $PhpDir
PhpSrc=php-$PhpVer.tar.bz2
if [ ! -f $PhpDir/$PhpSrc ]; then
    echo "Fetching $PhpSrc..."
    if [ $Maj -le 5 ]; then
	curl -sSL "http://$PHP5URL/$PhpSrc" -o $PhpDir/$PhpSrc
    else
	curl -sSL "http://$PHPSITE/get/$PhpSrc/from/this/mirror" -o $PhpDir/$PhpSrc
    fi
fi

#
#   Determine build number and build date
#
Num=$PhpDir/BUILD_NUM
Cmt="`git log -n1 --format=%H -- $Num 2>/dev/null`"
if [ "$Cmt" ]; then
    Log=`git show $Cmt:$Num`
    if [ -f $Num ]; then	# If $Num exists and is $Log, set it's mtime to $Cmt's
	test "`cat $Num`" = "$Log" && touch -d "`git show -s --format=%ci $Cmt`" $Num
    else			# else set $Num = $Log + 1
	echo `expr $Log + 1` >$Num
    fi
else				# No log yet: keep $Num or create it if needed
    test -f $Num || echo 1 >$Num
fi
Bld=`cat $Num`			# For package names
Dist=$DebDir/dist/$PhpVer-$Bld
test -d $Dist || mkdir -p $Dist
touch -r $Num $Dist/.date	# For package dates in changelog.Debian

#
#   Make build image and start container
#
BUILD_TOP=/opt/php-mk
BUILD_IMG=epi-build-php

echo "Making PHP $PhpVer-$Bld packages for Debian $DebVer..."
echo "Logs will be in $Dist/.logs/"
test -d $Dist/.logs && rm -f $Dist/.logs/*.out || mkdir $Dist/.logs

if [ -f $DebDir/Dockervars.sh ]; then
    . $DebDir/Dockervars.sh
else
    echo "$Prg: missing $DebDir/Dockervars.sh" >&2
    exit 1
fi
if [ -f php/$Maj/Dockervars.sh ]; then
    . php/$Maj/Dockervars.sh
else
    echo "$Prg: missing php/$Maj/Dockervars.sh" >&2
    exit 1
fi
test -f .norun && EXTCOPY="$EXTCOPY
COPY .norun $BUILD_TOP"
test -f php/.notest && EXTCOPY="$EXTCOPY
COPY php/.notest $BUILD_TOP"

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
#   Variables are by order of appearance in Dockerfile-build.in
DEBVER="$DebVer" BUILD_NUM="$Bld" CLI_DEPS="$CLI_DEPS" BUILD_REQ="$BUILD_REQ" BUILD_TOP="$BUILD_TOP" PHPSRC="$PhpDir/$PhpSrc" EXTCOPY="$EXTCOPY" PHPVER="$PhpVer" envsubst '$DEBVER $BUILD_NUM $CLI_DEPS $BUILD_REQ $BUILD_TOP $PHPSRC $EXTCOPY $PHPVER' <Dockerfile-build.in | tee $Dist/.logs/Dockerfile-build | docker build -f - -t $BUILD_IMG . >$Dist/.logs/docker-build.out 2>&1

echo "Running '$BUILD_IMG' container..."
Cmd="docker run -ti -v `pwd`/$Dist:$BUILD_TOP/dist --name $BUILD_IMG --rm $BUILD_IMG"
$Cmd
test -f .norun && echo "Use:\n    $Cmd bash\nto run the container again"

#
#   Make tests image and start container
#
TESTS_TOP=/opt/php-mk
TESTS_IMG=epi-tests-php
test -f .norun && EXTCOPY="COPY .norun $TESTS_TOP" || EXTCOPY=

if docker ps | grep $TESTS_IMG >/dev/null; then
    echo "Stopping running '$TESTS_IMG' container..."
    docker stop $TESTS_IMG >/dev/null
fi
if docker ps -a | grep $TESTS_IMG >/dev/null; then
    echo "Deleting existing '$TESTS_IMG' container..."
    docker rm $TESTS_IMG >/dev/null
fi
if docker images | grep $TESTS_IMG >/dev/null; then
    echo "Deleting existing '$TESTS_IMG' image..."
    docker rmi $TESTS_IMG >/dev/null
fi

echo "Building '$TESTS_IMG' image..."
DEBVER="$DebVer" TESTS_TOP="$TESTS_TOP" TESTS_REQ="$TESTS_REQ" EXTCOPY="$EXTCOPY" PHPVER="$PhpVer" envsubst '$DEBVER $TESTS_TOP $TESTS_REQ $EXTCOPY $PHPVER' <Dockerfile-tests.in | tee $Dist/.logs/Dockerfile-tests | docker build -f - -t $TESTS_IMG . >$Dist/.logs/docker-tests.out 2>&1

echo "Running '$TESTS_IMG' container..."
Cmd="docker run -ti -v `pwd`/$Dist:$TESTS_TOP/dist --name $TESTS_IMG --rm $TESTS_IMG"
$Cmd
test -f .norun && echo "Use:\n    $Cmd bash\nto run the container again"

#
#   End
#
date '+===== %Y-%m-%d %H:%M:%S %Z'
End=`date '+%s'`
Len=`expr $End - $Now`
Min=`expr $Len / 60`
Sec=`expr $Len - '(' $Min '*' 60 ')'`
printf "Duration: %d:%02d\n" $Min $Sec
