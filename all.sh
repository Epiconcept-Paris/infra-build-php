#!/bin/sh
#
#	all.sh - Build all latest PHP distribs, tools and multi
#
PHPSITE='fr.php.net'

Prg=`basename $0`
Dir=`dirname $0`

DEBS="8 9"
BUILD8="^(5\.[26]|7\.[12])\."
BUILD9="^(5\.6|7\.[012])\."

test "$Dir" = '.' || cd "$Dir"
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
test -d docker || { echo "$Prg: missing 'docker' directory." >&2; exit 1; }

Versions="`curl -sSL "http://$PHPSITE/ChangeLog-5.php" "http://$PHPSITE/ChangeLog-7.php" | sed -n 's/^.*<h[1-4]>Version \([^ ]*\) *<\/h[1-4]>/\1/p' | sort -nr -t. -k 1,1 -k 2,2 -k 3,3`"
if [ -z "$Versions" ]; then
    echo "$Prg: unable to fetch the latest lists of PHP versions from \"$PHPSITE\"" >&2
    echo "$Prg: using instead the list of versions already known" >&2
    Versions="`ls -d php/[5-9]/[5-9].* | sed 's;^php/./;;' | sort -nr -t. -k 1,1 -k 2,2 -k 3,3`"
fi
Latest="`echo "$Versions" | grep -v '^5\.[01345]\.' | awk -F. '{
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
    re=`eval echo "\\$BUILD$d"`
    for v in `echo "$Latest" | egrep "$re"`
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
	    ./mk.sh $v $d | sed -u 's/$//' | tee $Dir/mk.out | sed -u 's/$//'
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
	    tools/mk.sh $d | sed -u 's/$//' | tee $Dir/mk.out | sed -u 's/$//'
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
	test -d $Dir || mkdir $Dir
	eval ./multi.sh \$MUL$d | sed -u 's/$//' | tee $Dir/mk.out | sed -u 's/$//'
    fi
fi
