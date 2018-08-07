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
    d=`expr "$arg" : '\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*-[0-9][0-9]*\)$'`
    v=`expr "$arg" : '\([0-9][0-9]\)$'`
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
MultDir=$DistDir/multi
test -d $MultDir || mkdir $MultDir
#
#   Check PHP-dists
#
DistOK()
{
    # global Base Arch
    local path dist mm
    path="$1"
    test -d "$path" || return 1
    dist=`basename $path`
    mm=`expr "$dist" : '\([0-9][0-9]*\.[0-9][0-9]*\)\.[0-9][0-9]*-[0-9][0-9]*$'`
    test "$mm" || return 1
    test -f $path/$Base-$mm-cli_${dist}_$Arch.deb || return 1
    test -f $path/$Base-$mm-fpm_${dist}_$Arch.deb || return 1
    return 0
}

if [ "$ds" ]; then
    Sep=''
    for d in $ds
    do
	if DistOK $DistDir/$d; then
	    Dists="$Dists$Sep$d"
	    Sep="$LF"
	else
	    echo "$Prg: $d does not contain any valid $Base package" >&2
	    exit 1
	fi
    done
fi
if [ "$Dists" ]; then
    echo "$Dists" >$MultDir/.dists
else
    echo "Usage: $Dir/$Prg <PHP-dist-dir> [<PHP-dist-dir> ...] [<Debian-version>]" >&2
    echo "Available dists for Debian version $DebNum ($DebVer):" >&2
    Sep=''
    for dir in $DistDir/[5-9].[0-9]*.[0-9]*-[0-9]*
    do
	if DistOK $dir; then
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
if docker images | grep "$MULTI_BASE *$DebVer" >/dev/null; then
    echo "Deleting the existing '$MULTI_IMG' image..."
    docker rmi $MULTI_IMG >/dev/null
fi

echo "Building the '$MULTI_IMG' image..."
DEBVER="$DebVer" MULTI_TOP="$MULTI_TOP" MULTI_REQ="$MULTI_REQ" envsubst '$DEBVER $MULTI_TOP $MULTI_REQ' <Dockerfile-multi.in | tee $MultDir/Dockerfile-multi | docker build -f - -t $MULTI_IMG . >$MultDir/docker-multi.out 2>&1
#
#   Run container
#
echo "Running the '$MULTI_NAME' container..."
test -f .norun && Opt='-ti' || Opt='-d'
Cmd="docker run $Opt -p 80:80 -v `pwd`/$DistDir:$MULTI_TOP/work --name $MULTI_NAME --rm $MULTI_IMG"
test -f .norun && echo "$Cmd bash" || $Cmd
