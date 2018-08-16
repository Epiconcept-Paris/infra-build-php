#!/bin/sh
#
#	all.sh - Build all latest PHP distribs, tools and multi
#
Prg=`basename $0`
Dir=`dirname $0`
DEBS="8 9"
LATEST8="5.2.17 5.6.37 7.1.20 7.2.8"
LATEST9="5.6.37 7.0.31 7.1.20 7.2.8"

test "$Dir" = '.' || cd "$Dir"
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
test -d docker || { echo "$Prg: missing 'docker' directory." >&2; exit 1; }

rm=
mk=y
if [ $# -gt 0 ]; then
    mk=
    for arg in "$@"
    do
	case "$arg" in
	    rm)	rm=y;;
	    mk) mk=y;;
	    *)	echo "$Prg: invalid command '$arg'" >&2; exit 1;;
	esac
    done
fi

>.debug
for d in $DEBS
do
    n=`cat debian/$d/name`
    for v in `eval echo "\\$LATEST$d"`
    do
	eval `echo "$v" | sed -nr 's/^([57])\.([0-9])\.([0-9]+)$/Maj=\1 Min=\2 Rel=\3/p'`
	#echo "v=$v Maj=$Maj"
	test -f php/$Maj/$v/BUILD_NUM || continue
	Bld=`cat php/$Maj/$v/BUILD_NUM`
	Dir=debian/$d/dist/$v-$Bld
	if [ "$rm" ]; then
	    test -d $Dir && echo "Removing $v for $n"
	    rm -rf $Dir
	    for p in build tests
	    do
		docker images | grep "epi-$p-php  *$n-$v" >/dev/null && docker rmi epi-$p-php:$n-$v >/dev/null
	    done
	fi
	if [ "$mk" ]; then
	    if [ -d $Dir ]; then
		echo "$v is already built for $n"
		continue
	    fi
	    echo "Building $v for $n in $Dir"
	    mkdir -p $Dir
	    ./mk.sh $v $d >$Dir/mk.out
	    eval "MUL$d=\"\$MUL$d\$v-\$Bld \""
	fi
    done
done
#echo "d=$d n=$n"

#eval "echo MUL$d=\\\"\$MUL$d\\\""
if [ "$rm" ]; then
    docker ps | grep epi_multi_php >/dev/null && docker stop epi_multi_php
    rm -rf debian/$d/dist/tools debian/$d/multi
    for p in tools multi-php
    do
	docker images | grep "epi-$p  *$n" >/dev/null && docker rmi epi-$p:$n >/dev/null
    done
fi
if [ "$mk" ]; then
    if [ -d debian/$d/dist/tools ]; then
	echo "tools are already built for $n"
    else
	tools/mk.sh
    fi
    if docker images | grep "epi-multi-php  *$n" >/dev/null; then
	echo "multi is already built for $n"
    else
	eval ./multi.sh \$MUL$d
    fi
fi
