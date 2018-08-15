#!/bin/sh
#
#	Test the use of multiple PHP versions
#
#	Usage:	./multi.sh <PHP-dist-dir> [<PHP-dist-dir> ...] [<Debian-version>]
#
Prg=`basename $0`
Dir=`dirname $0`
Base='epi-php'
Arch='amd64'
LF='
'

test "$Dir" = '.' || cd "$Dir"
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
DefDeb=`ls debian | sort -n | tail -1`	# Default = latest

#
#    Parse args
#
for arg in "$@"
do
    d=`expr "$arg" : '\([5-9]\.[0-9]\.[0-9][0-9]*-[0-9][0-9]*\)$'`
    v=`expr "$arg" : '\([0-9][0-9]*\)$'`
    if [ "$d" ]; then
	ds="$ds $d"
    elif [ "$v" ]; then
	vs="$vs $v"
    else
	echo "$Prg: invalid PHP-dist-dir or Debian-version \"$arg\"" >&2
	exit 1
    fi
done
#
#   Check Debian version
#
for v in $vs
do
    if [ $v != 8 -a -f debian/$v/name ]; then
	test "$DebNum" && echo "$Prg: discarding previously given Debian-version $DebNum (`cat debian/$DebNum/name`)" >&2
	DebNum="$v"
    else
	echo "$Prg: unsupported Debian version \"$v\"" >&2
	echo "Supported Debian versions (default $DefDeb):" >&2
	ls debian | sort -n | grep -v '^8$' | while read v; do test -f debian/$v/name && printf "    %2d (`cat debian/$v/name`)\n" $v; done >&2
	exit 1
    fi
done
test "$DebNum" || DebNum=$DefDeb
DebVer="`cat debian/$DebNum/name`"
DebDir=debian/$DebNum

if [ -f $DebDir/Dockervars.sh ]; then
    eval `sed -n 's/^TESTS_REQ=/MULTI_REQ=/p' $DebDir/Dockervars.sh`
else
    echo "$Prg: missing $DebDir/Dockervars.sh" >&2
    exit 1
fi
DistDir=$DebDir/dist
MultDir=$DebDir/multi
Logs=$MultDir/logs
Pkgs=$MultDir/pkgs
#
#   Check PHP-dists
#
DistOK()
{
    # global Base Arch
    local path dist
    path="$1"
    test -d "$path" || return 1
    dist=`basename $path`
    test -s $path/$Base-$2.$3-cli_${dist}_$Arch.deb || return 1
    test -s $path/$Base-$2.$3-fpm_${dist}_$Arch.deb || return 1
    return 0
}

nd=0
test -d $Pkgs && rm -f $Pkgs/*.deb || mkdir -p $Pkgs
if [ "$ds" ]; then
    for d in $ds
    do
	eval `echo "$d" | sed -nr 's/^([5-9])\.([0-9])\.([0-9]+)-([0-9]+)$/Maj=\1 Min=\2 Rel=\3 Bld=\4/p'`
	if DistOK $DistDir/$d $Maj $Min; then
	    ln $DistDir/$d/$Base-$Maj.$Min-cli_${d}_$Arch.deb $Pkgs
	    ln $DistDir/$d/$Base-$Maj.$Min-fpm_${d}_$Arch.deb $Pkgs
	    test -s $DistDir/$d/$Base-$Maj.$Min-mysql_${d}_$Arch.deb && ln $DistDir/$d/$Base-$Maj.$Min-mysql_${d}_$Arch.deb $Pkgs
	    test "$HOSTFMT" && h=`echo "$HOSTFMT" | awk -F. '{print $1}' | sed -e "s/%M/$Maj/" -e "s/%m/$Min/"` || h=php$Maj$Min
	    w=$MultDir/www/$h
	    test -d $w || mkdir -p $w
	    test -f $w/index.php || echo "<?php header('Location: info.php'); ?>" >$w/index.php
	    cp -p php/info.php $w
	    nd=`expr $nd + 1`
	else
	    echo "$Prg: $d does not contain the necessary $Base cli and fpm packages" >&2
	    exit 1
	fi
    done
fi
if [ $nd -eq 0 ]; then
    echo "Usage: $Dir/$Prg <PHP-dist-dir> [<PHP-dist-dir> ...] [<Debian-version>]" >&2
    echo "Available dists for Debian version $DebNum ($DebVer):" >&2
    Sep=''
    for dir in $DistDir/[5-9].[0-9].[0-9]*-[0-9]*
    do
	eval `basename $dir | sed -nr 's/^([5-9])\.([0-9])\.([0-9]+)-([0-9]+)$/Maj=\1 Min=\2 Rel=\3 Bld=\4/p'`
	if DistOK $dir $Maj $Min; then
	    Dists="$Dists$Sep`basename $dir`"
	    Sep="$LF"
	fi
    done
    echo "$Dists" | sed 's/^/    /' >&2
    exit 1
fi

#
#   Build container
#
MULTI_TOP=/opt/multi
MULTI_BASE=epi-multi-php
MULTI_IMG=$MULTI_BASE:$DebVer
MULTI_NAME=epi_multi_php

if docker ps | grep $MULTI_NAME >/dev/null; then
    echo "Stopping the running '$MULTI_NAME' container..."
    docker stop -t 5 $MULTI_NAME >/dev/null
    while docker ps | grep $MULTI_NAME >/dev/null
    do
	sleep 1
    done
fi
if docker ps -a | grep $MULTI_NAME >/dev/null; then
    echo "Deleting the existing '$MULTI_NAME' container..."
    docker rm $MULTI_NAME >/dev/null
fi

test -d $Logs || mkdir -p $Logs
if docker images | grep "$MULTI_BASE *$DebVer" >/dev/null; then
    echo "Re-using the existing '$MULTI_IMG' image. Use:\n    docker rmi $MULTI_IMG\nto force a rebuild."
else
    echo "Building the '$MULTI_IMG' image..."
    #
    #   Find the waitpid package
    #
    WaitPkg=`ls $DistDir/tools/epi-tools-waitpid_*_amd64.deb 2>/dev/null`
    if [ -z "$WaitPkg" ]; then
	tools/mk.sh
	WaitPkg=`ls $DistDir/tools/epi-tools-waitpid_*_amd64.deb 2>/dev/null`
	if [ -z "$WaitPkg" ]; then
	    echo "Cannot build the waitpid package, needed to build the '$MULTI_IMG' image" >&2
	    exit 1
	fi
    fi
    #   Variables come in order of their appearance in Dockerfile-multi.in
    DEBVER="$DebVer" MULTI_TOP="$MULTI_TOP" MULTI_REQ="$MULTI_REQ" WAITPKG="$WaitPkg" envsubst '$DEBVER $MULTI_TOP $MULTI_REQ $WAITPKG' <Dockerfile-multi.in | tee $Logs/Dockerfile-multi | docker build -f - -t $MULTI_IMG . >$Logs/docker-build.out 2>&1
fi
#
#   Run container
#
test "$HOSTFMT" && RunEnv=' -e HOSTFMT'
RunCmd()
{
    echo "docker run $1$RunEnv -p 80:80 -v `pwd`/$MultDir:$MULTI_TOP/work --name $MULTI_NAME --rm $MULTI_IMG"
}
if [ -f .norun ]; then
    echo "Use:\n    `RunCmd -ti` bash\nto run the container"
else
    echo "Running the '$MULTI_NAME' container in background mode:\n    `RunCmd -d`"
    `RunCmd -d` >/dev/null
    while :
    do
	sleep 1
	grep '^Waiting for container stop' $Logs/docker-run.out >/dev/null && break
    done
    nd=`expr $nd + 1`
    sed -n "1,${nd}p" $Logs/docker-run.out
    echo "Use:\n    docker stop $MULTI_NAME\nto stop the container, and use:"
    echo "    `RunCmd -ti` bash\nto run the container in the foreground"
fi
