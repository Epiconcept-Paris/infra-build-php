#!/bin/sh
#
#	all.sh - Build all latest PHP distribs, tools and multi
#
PHPSITE='fr.php.net'

Prg=`basename $0`
Dir=`dirname $0`
#Do=:	# Remove comment to not actually execute commands (for debug)

LF='
'

test "$Dir" = '.' || cd "$Dir"
test -d debian || { echo "$Prg: missing 'debian' directory." >&2; exit 1; }
test -d docker || { echo "$Prg: missing 'docker' directory." >&2; exit 1; }

#
#   Parse args (rm or mk so far)
#
if [ $# -gt 0 ]; then
    mk=
    while [ "$1" ]
    do
	case "$1" in
	    mk) mk=y;;
	    rm)	rm=y;;
	    *)	echo "$Prg: invalid argument '$1'" >&2
		exit 1
		;;
	esac
	shift
    done
fi
test -z "$mk" -a -z "$rm" && mk=y

for f in debian/*/name
do
    Dir=`dirname $f`
    test $Dir/mkre || continue
    DebVer="$DebVer`basename $Dir` "
done
test "$Do" && echo "rm=$rm mk=$mk DebVer=\"$DebVer\""

if [ "$mk" ]; then
    #
    #   Get the latest versions
    #
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
    test "$Do" && >.debug
fi
#
#   Loop on debian versions
#
for d in $DebVer
do
    n=`cat debian/$d/name`
    if [ "$rm" ]; then
	#   We have to remove old docker images and dist directories
	Imgs="`docker images | sed -nr "s/^epi-(build|tests)-php  *$n-([^ ]+) .*$/\2/p"`"
	Dirs="`ls -d debian/$d/dist/[5-9].* 2>/dev/null | sed -r 's;^.*/([^-/]+)-[0-9]+*$;\1;')`"
	for v in `echo "$Imgs$LF$Dirs" | sort -u`
	do
	    echo -n "Removing $v for $n: "
	    Imgs="`docker images | sed -nr "s/^(epi-(build|tests)-php)  *($n-$v) .*$/\1:\3/p"`"
	    if [ "$Imgs" ]; then
		echo -n "docker images"
		$Do docker rmi $Imgs >/dev/null
	    fi
	    Dirs="`ls -d debian/$d/dist/$v-* 2>/dev/null`"
	    if [ "$Dirs" ]; then
		test "$Imgs" && echo -n ", "
		echo -n "debian/$d/dist dirs"
		$Do rm -rf $Dirs
	    fi
	    echo
	    test "$Do" -a "$Imgs" && echo "docker rmi " $Imgs
	    test "$Do" -a "$Dirs" && echo "rm -rf " $Dirs
	    test "$Do" && echo ---------------------
	done

	Dir=debian/$d/dist/tools
	Img="`docker images | sed -nr "s/^(epi-tools)  *($n) .*$/\1:\2/p"`"
	if [ "$Img" -o -d $Dir ]; then
	    echo -n "Removing tools for $n: "
	    test "$Img" && { echo -n "docker image"; $Do docker rmi $Img >/dev/null; }
	    test -d $Dir && { test "$Img" && echo -n ", "; echo -n $Dir; $Do rm -rf $Dir; }
	    echo
	fi
    fi
    if [ "$mk" ]; then
	re=`cat debian/$d/mkre`
	for v in `echo "$Latest" | egrep "^($re)\."`
	do
	    eval `echo "$v" | sed -nr 's/^([57])\.([0-9])\.([0-9]+)$/Maj=\1 Min=\2 Rel=\3/p'`
	    test "$Do" && echo "v=$v Maj=$Maj"
	    if [ ! -s php/$Maj/$v/BUILD_NUM ]; then
		test -d php/$Maj/$v || mkdir php/$Maj/$v
		echo 1 >php/$Maj/$v/BUILD_NUM
	    fi
	    Bld=`cat php/$Maj/$v/BUILD_NUM`
	    Dir=debian/$d/dist/$v-$Bld
	    if [ -d $Dir ]; then
		echo "$v is already built for $n"
		continue
	    fi
	    echo "Building $v for $n in $Dir"
	    $Do mkdir -p $Dir
	    $Do ./mk.sh $v $d | sed -u 's/$//' | $Do tee $Dir/mk.out | sed -u 's/$//'
	    eval "MUL$d=\"\$MUL$d\$v-\$Bld \""
	done

	Dir=debian/$d/dist/tools
	if [ -d $Dir ]; then
	    echo "tools are already built for $n"
	else
	    echo "Building tools for $n"
	    $Do mkdir -p $Dir
	    $Do tools/mk.sh $d | sed -u 's/$//' | $Do tee $Dir/mk.out | sed -u 's/$//'
	fi
    fi
done
eval "Mul=\$MUL$d"
test "$Do" && echo "d=$d n=$n Mul=\"$Mul\""

#
#   Multi
#
Dir=debian/$d/multi
Img="`docker images | sed -nr "s/^(epi-multi-php)  *($n) .*$/\1:\2/p"`"
if [ "$rm" ]; then
    if [ "$Img" -o -d $Dir ]; then
	echo -n "Removing multi for $n: "
	docker ps | grep epi_multi_php >/dev/null && docker stop epi_multi_php
	test "$Img" && { echo -n "docker image"; $Do docker rmi $Img >/dev/null; }
	test -d $Dir && { test "$Img" && echo -n ", "; echo -n $Dir; $Do rm -rf $Dir; }
	echo
    fi
fi
if [ "$mk" ]; then
    if [ "$Img" ]; then
	echo "multi is already built for $n"
    elif [ "$Mul" ]; then
	echo "Building and running multi for $n with $Mul"
	test -d $Dir || $Do mkdir $Dir
	$Do ./multi.sh $Mul | sed -u 's/$//' | $Do tee $Dir/mk.out | sed -u 's/$//'
    fi
fi
