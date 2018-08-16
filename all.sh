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
	    ./mk.sh $v $d | sed -u 's/$//' | tee $Dir/mk.out
	    eval "MUL$d=\"\$MUL$d\$v-\$Bld \""
	fi
    done
    Dir=debian/$d/dist/tools
    if [ "$rm" ]; then
	test -d $Dir && echo "Removing tools for $n"
	rm -rf $Dir
	docker images | grep "epi-tools  *$n" >/dev/null && docker rmi epi-tools:$n >/dev/null
    fi
    if [ "$mk" ]; then
	if [ -d $Dir ]; then
	    echo "tools are already built for $n"
	else
	    echo "Building tools for $n"
	    mkdir -p $Dir
	    tools/mk.sh $d | sed -u 's/$//' | tee $Dir/mk.out
	fi
    fi
done
#echo "d=$d n=$n"

#eval "echo MUL$d=\\\"\$MUL$d\\\""
Dir=debian/$d/multi
if [ "$rm" ]; then
    test -d $Dir && echo "Removing multi for $n"
    docker ps | grep epi_multi_php >/dev/null && docker stop epi_multi_php
    rm -rf $Dir
    docker images | grep "epi-multi-php  *$n" >/dev/null && docker rmi epi-multi-php:$n >/dev/null
fi
if [ "$mk" ]; then
    if docker images | grep "epi-multi-php  *$n" >/dev/null; then
	echo "multi is already built for $n"
    else
	eval "echo \"Building and running multi for $n with \$MUL$d\""
	eval ./multi.sh \$MUL$d
    fi
fi
