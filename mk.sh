#!/bin/sh
#
#	Make PHP packages for a given set of PHP and Debian versions
#
#	Usage:	./mk.sh <PHP-version> [<Debian-version>]
#
#	PHP-version is checked to be available in PHP sources on $PHPSITE
#	Supported PHP versions are 5.2, 5.6, 7.1+ on jessie, 5.6 and 7.1+ on later Debian
#	Debian-version is checked to be supported and defaults to latest version
#
PHPSITE='fr.php.net'
PHP5URL="museum.php.net/php5"
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
# From $Versions isolate latest rel for each Maj.min
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

SupPhp()
{
    # global Latest
    local sup flt
    test "$1" && sup=" supported" || sup=
    test "$1" && flt="| grep -v '^5\.[01345]\.'" || flt=
    echo "Latest$sup PHP 5/7 versions:" >&2
    eval "echo \"$Latest\" $flt | sed 's/^/    /'" >&2
}

SupDeb()
{
    # global DebNum
    local v
    echo "Supported Debian versions (default $DebNum):" >&2
    ls debian | sort -n | while read v; do test -f debian/$v/name && printf "    %2d (`cat debian/$v/name`)\n" $v; done >&2
}

#
#   Check usage
#
test "$Dir" = '.' || cd "$Dir"
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
DebNum=`ls debian | sort -n | tail -1`	# Default = latest
if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $Dir/$Prg <PHP-version> [ <Debian-version> ]" >&2
    SupPhp -
    SupDeb
    exit 1
fi

#
#   Check PHP version
#
split="`echo "$1" | sed -nr 's/^([57])\.([0-9])\.([0-9]+)$/Maj=\1 Min=\2 Rel=\3/p'`"
if [ -z "$split" ]; then
    echo "$Prg: invalid PHP version \"$1\" ([57].x.y)" >&2
    exit 1
fi
eval "$split"
if echo "$Versions" | grep "^$Maj\.$Min\.$Rel$" >/dev/null; then
    PhpVer="$1"
    PhpDir=php/$Maj/$PhpVer
else
    echo "$Prg: unknown PHP version \"$1\"" >&2
    SupPhp
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
	SupDeb
	exit 1
    fi
fi
DebVer="`cat debian/$DebNum/name`"
DebDir=debian/$DebNum
Tag=$DebVer-$PhpVer
#echo "DebVer=$DebVer PhpVer=$PhpVer Maj=$Maj Min=$Min Rel=$Rel"

#
#   Fetch PHP source
#
date '+===== %Y-%m-%d %H:%M:%S %Z =================='
Now=`date '+%s'`
test -d $PhpDir || mkdir $PhpDir
PhpSrc=php-$PhpVer.tar.bz2
PhpLst=php-$PhpVer.files
if [ ! -f $PhpDir/$PhpSrc ]; then
    echo "Fetching $PhpSrc..."
    test $Maj -le 5 && PhpUrl="http://$PHP5URL/$PhpSrc" || PhpUrl="http://$PHPSITE/get/$PhpSrc/from/this/mirror"
    curl -sSL $PhpUrl -o $PhpDir/$PhpSrc
fi
if [ ! -f $PhpDir/$PhpLst ]; then
    if ! tar tf $PhpDir/$PhpSrc >$PhpDir/$PhpLst 2>/dev/null; then
	echo "$Prg: cannot fetch $PhpUrl" >&2
	rm -f $PhpDir/$PhpSrc $PhpDir/$PhpLst
	exit 1
    fi
fi

#
#   Source debian and PHP hooks (in that order)
#
BUILD_TOP=/opt/php-mk
TESTS_TOP=/opt/php-mk

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

echo "Making PHP $PhpVer-$Bld packages for Debian $DebVer..."
echo "Logs will be in $Dist/.logs/"
test -d $Dist/.logs && rm -f $Dist/.logs/*.out || mkdir $Dist/.logs

#
#   Make build image and start container
#
BUILD_BASE=epi-build-php
BUILD_IMG=$BUILD_BASE:$Tag	# Keep all build images separate
BUILD_NAME=epi_build_php	# Only one build container at a time

test -f .debug && BLDCOPY="$BLDCOPY
COPY .debug $BUILD_TOP"
test -f php/.notest && BLDCOPY="$BLDCOPY
COPY php/.notest $BUILD_TOP"

if docker ps | grep $BUILD_NAME >/dev/null; then
    echo "Stopping the running '$BUILD_NAME' container..."
    docker stop -t 5 $BUILD_NAME >/dev/null
    while docker ps | grep $BUILD_NAME >/dev/null
    do
	sleep 1
    done
fi
if docker ps -a | grep $BUILD_NAME >/dev/null; then
    echo "Deleting the existing '$BUILD_NAME' container..."
    docker rm $BUILD_NAME >/dev/null
fi
if docker images | grep "$BUILD_BASE *$Tag" >/dev/null; then
    echo "Deleting the existing '$BUILD_IMG' image..."
    docker rmi $BUILD_IMG >/dev/null
fi

echo "Building the '$BUILD_IMG' image..."
User=`id -un`
AddUser="groupadd -g `id -g` `id -gn`; useradd -u `id -u` -g `id -g` $User"
#   Variables come in order of their appearance in Dockerfile-build.in
DEBVER="$DebVer" CLI_DEPS="$CLI_DEPS" BUILD_NUM="$Bld" USER="$User" BUILD_TOP="$BUILD_TOP" PHPVER="$PhpVer" ADDUSER="$AddUser" BUILD_REQ="$BUILD_REQ" PHPSRC="$PhpDir/$PhpSrc" BLDCOPY="$BLDCOPY" envsubst '$DEBVER $CLI_DEPS $BUILD_NUM $USER $BUILD_TOP $PHPVER $ADDUSER $BUILD_REQ $PHPSRC $BLDCOPY' <Dockerfile-build.in | tee $Dist/.logs/Dockerfile-build | docker build -f - -t $BUILD_IMG . >$Dist/.logs/docker-build.out 2>&1

Cmd="docker run -ti -v $PWD/$Dist:$BUILD_TOP/dist --name $BUILD_NAME --rm $BUILD_IMG"
if [ -f .norun ]; then
    echo "Use:\n    $Cmd bash\nto run the build container"
else
    echo "Running the '$BUILD_NAME' container:\n    $Cmd"
    $Cmd
fi
echo "------------------------------------------------"

#
#   Make tests image and start container
#
TESTS_BASE=epi-tests-php
TESTS_IMG=$TESTS_BASE:$Tag	# Keep all tests images separate
TESTS_NAME=epi_tests_php	# Only one tests container at a time

if docker ps | grep $TESTS_NAME >/dev/null; then
    echo "Stopping the running '$TESTS_NAME' container..."
    docker stop -t 5 $TESTS_NAME >/dev/null
    while docker ps | grep $TESTS_NAME >/dev/null
    do
	sleep 1
    done
fi
if docker ps -a | grep $TESTS_NAME >/dev/null; then
    echo "Deleting the existing '$TESTS_NAME' container..."
    docker rm $TESTS_NAME >/dev/null
fi
if docker images | grep "$TESTS_BASE *$Tag" >/dev/null; then
    echo "Deleting the existing '$TESTS_IMG' image..."
    docker rmi $TESTS_IMG >/dev/null
fi

echo "Building the '$TESTS_IMG' image..."
#   Variables come in order of their appearance in Dockerfile-tests.in
DEBVER="$DebVer" TESTS_TOP="$TESTS_TOP" TESTS_REQ="$TESTS_REQ" TSTCOPY="$TSTCOPY" envsubst '$DEBVER $TESTS_TOP $TESTS_REQ $TSTCOPY' <Dockerfile-tests.in | tee $Dist/.logs/Dockerfile-tests | docker build -f - -t $TESTS_IMG . >$Dist/.logs/docker-tests.out 2>&1

Cmd="docker run -ti -v $PWD/$Dist:$TESTS_TOP/dist --name $TESTS_NAME --rm $TESTS_IMG"
if [ -f .norun ]; then
    echo "Use:\n    $Cmd bash\nto run the tests container"
else
    echo "Running the '$TESTS_NAME' container:\n    $Cmd"
    $Cmd
fi

#
#   End
#
date '+===== %Y-%m-%d %H:%M:%S %Z =================='
End=`date '+%s'`
Len=`expr $End - $Now`
Min=`expr $Len / 60`	# $Min above not needed anymore
Sec=`expr $Len - '(' $Min '*' 60 ')'`
printf "Duration: %d:%02d\n" $Min $Sec
