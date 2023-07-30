#!/bin/sh
#
#	savedist.sh - Save prod versions in '../php-debs' side directory
#
# shellcheck disable=SC2164	# Use 'cd ... || exit'
# shellcheck disable=SC2039	# In POSIX sh, 'local' is undefined
#
Usr=$(id -un)
Prg="$(basename "$0")"
Dir="$(dirname "$0")"
cd "$Dir"

DebDir='../php-debs'
NoDir="$Prg: cannot find directory"
DkIms="$(docker images | awk '$1 ~ /^epi-(build|tests)-php$/ {print $1 ":" $2}')"
#echo "$DkIms"; exit 0	# DBG

test "$*" && echo "NOTE: arguments '$*' to $Prg will be ignored" >&2
test "$Usr" = 'php' || { echo "$Prg: for the 'php' user only" >&2; exit 1; }
test -d 'debian' || { echo "$NoDir 'debian' in '$PWD'" >&2; exit 1; }

#   Test below assumes 'php-prod' and 'infra-build-php' are not in the same dir
test -d "$DebDir" || { echo "$NoDir '$(basename "$DebDir")' in '$(dirname "$PWD")'" >&2; exit 1; }

#   Return deb-name given deb-num
debname()
{
    case $1 in
	 8) n='jessie';;
	 9) n='stretch';;
	10) n='buster';;
	11) n='bullseye';;
	12) n='bookworm';;
	13) n='trixie';;
    esac
    echo $n
}

#   Remove docker images for Debian $1, PHP $2
rmdkim()
{
    local dn

    dn="$(debname "$1")-$(expr "$2" : '\([^-]*\)')"
    for type in 'build' 'tests'
    do
	img="epi-$type-php:$dn"
	echo "$DkIms" | grep "^$img$" >/dev/null && docker rmi "$img" >/dev/null 2>&1 && echo "Removed docker image $img"
    done
}

XC=0
for dv in $(cd 'debian'; echo [0-9] [0-9][0-9])
do
    for d in "debian/$dv/dist"/* "debian/$dv/multi"
    do
	test -d "$d" || continue	# Skip if pattern does not exist
	pv=$(basename "$d")
	bad=
	case "$pv" in
	    [5-9].*)	eval "$(echo "$pv" | sed -r 's/^([.0-9]+)-([0-9]+)$/phpver=\1 bldnum=\2/')"
			bin/chkdebs $dv "$phpver" "$bldnum" >/dev/null 2>&1 || bad=y
			;;
	    tools)	test -f "$d"/epi-tools-waitpid_*.deb || bad=y;;
	    multi)	test -d "$d"/pkgs -a -d "$d"/logs || bad=y;;
	esac
	test "$bad" && { echo "Skipping $d (incomplete build)" >&2; continue; }
	if [ -d "$DebDir/$dv/$pv" ]; then
	    diff=
	    for f in $(find "$d" -type f | sed "s;^$d/;;")
	    do
		cmp "$d/$f" "$DebDir/$dv/$pv/$f" >/dev/null 2>&1 || { diff='y'; break; }
	    done
	    if [ "$diff" ]; then
		echo "Dist $d differs from $DebDir/$dv/$pv - rename/delete that if needed"
		#test $XC -eq 0 && XC=1
	    else
		echo "Dist $d is already saved"
		test "$pv" != 'multi' -a "$pv" != 'tools' && rmdkim "$dv" "$pv"
	    fi
	else
	    echo "Saving $d"
	    if [ "$pv" = 'multi' ]; then
		tar Ccf "debian/$dv" - "$pv" | tar Cxf "$DebDir/$dv" -
	    else
		tar Ccf "debian/$dv/dist" - "$pv" | tar Cxf "$DebDir/$dv" -
	    fi
	    xc=$?
	    if [ $xc -eq 0 ]; then
		test "$pv" != 'multi' -a "$pv" != 'tools' && rmdkim "$dv" "$pv"
	    else
		test $XC -eq 0 && XC=$xc
	    fi
	fi
    done
done
exit $XC
