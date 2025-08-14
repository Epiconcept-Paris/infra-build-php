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
MaxMv=100	# Max backup copies (should be a power of 10)
command -v docker >/dev/null && DkIms="$(docker images | awk '$1 ~ /^epi-[^-]+-php$/ {print $1 ":" $2}')"
#echo "$DkIms"; exit 0	# DBG

toMv=
toRm=
Cmt="# Pipe this to /bin/sh (after editing if needed)\n"
NotBoth="$Prg: cannot use both '%s' AND '%s'\n"
for opt in "$@"
do
    case "$opt" in
	mv)	test "$toRm" && { printf "$NotBoth" rm mv >&2; exit 1; } || toMv="$Cmt" ;;
	rm)	test "$toMv" && { printf "$NotBoth" mv rm >&2; exit 1; } || toRm="$Cmt" ;;
	*)	echo "Usage: $Prg [ rm | mv ]" >&2; exit 1;;
    esac
done
test "$Usr" = 'php' || { echo "$Prg: for the 'php' user only" >&2; exit 1; }
test -d 'debian' || { echo "$NoDir 'debian' in '$PWD'" >&2; exit 1; }

#   Test below assumes 'php-prod' and 'infra-build-php' are not in the same dir
test -d "$DebDir" || { echo "$NoDir '$(basename "$DebDir")' in '$(dirname "$PWD")'" >&2; exit 1; }

#   Return deb-name given deb-num
debname()
{
    local n

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
    #global DkIms
    local tag type img

    test "$DkIms" || return
    tag="$(debname "$1")-$(expr "$2" : '\([^-]*\)')"
    for type in 'build' 'tests'
    do
	img="epi-$type-php:$tag"
	echo "$DkIms" | grep -q "^$img$" && docker rmi "$img" >/dev/null 2>&1 && echo "Removed docker image $img"
    done
}

#   Find an archive name for dir $1
arch()
{
    #global MaxMv
    local d n

    n=0
    while [ "$n" -lt $MaxMv ]
    do
	d="$1:$(printf "%0$(expr $((MaxMv-1)) : '.*')d" $n)"
	test -d "$d" || { echo "$d"; return; }
	n=$((n + 1))
    done
    echo "$1:--"
}

nbg=0	# Number of good saves
nbf=0	# Number of failed saves
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
			bin/chkdebs "$dv" "$phpver" "$bldnum" >/dev/null 2>&1 || bad=y
			;;
	    tools)	test -f "$d"/epi-tools-waitpid_*.deb || bad=y;;
	    multi)	test -d "$d"/pkgs -a -d "$d"/logs || bad=y;;
	esac
	test "$bad" && { echo "Skipping $d (incomplete build)" >&2; nbf=$((nbf + 1)); continue; }
	test -d "$DebDir/$dv" || mkdir "$DebDir/$dv"
	if [ -d "$DebDir/$dv/$pv" ]; then
	    diff=
	    for f in $(find "$d" -type f | sed "s;^$d/;;")
	    do
		cmp "$d/$f" "$DebDir/$dv/$pv/$f" >/dev/null 2>&1 || { diff='y'; break; }
	    done
	    if [ "$diff" ]; then
		if [ "$toMv" ]; then
		    new="$(arch "$DebDir/$dv/$pv")"
		    if [ "$new" != "$DebDir/$dv/$pv:--" ]; then
			toMv="${toMv}mv -v \"$DebDir/$dv/$pv\" \"$new\"\n"
		    else
			echo "Cannot create 101st archive of '$DebDir/$dv/$pv'" >&2
		    fi
		elif [ "$toRm" ]; then
		    toRm="${toRm}rm -r \"$DebDir/$dv/$pv\"\n"
		else
		    echo "Dist $d differs from $DebDir/$dv/$pv - mv/rm the latter as needed" >&2
		    #test $XC -eq 0 && XC=1
		fi
	    else
		nbg=$((nbg + 1))
		echo "Dist $d is already saved" >&2
		test "$pv" != 'multi' -a "$pv" != 'tools' && rmdkim "$dv" "$pv"
	    fi
	else
	    echo "Saving $d" >&2
	    if [ "$pv" = 'multi' ]; then
		tar Ccf "debian/$dv" - "$pv" | tar Cxf "$DebDir/$dv" -
	    else
		tar Ccf "debian/$dv/dist" - "$pv" | tar Cxf "$DebDir/$dv" -
	    fi
	    xc=$?
	    if [ $xc -eq 0 ]; then
		nbg=$((nbg + 1))
		test "$pv" != 'multi' -a "$pv" != 'tools' && rmdkim "$dv" "$pv"
	    else
		test $XC -eq 0 && XC=$xc
	    fi
	fi
    done
done
test "$toRm" && echo "$toRm"
test "$toMv" && echo "$toMv"
test $XC -eq 0 -a $nbg -eq 0 -a $nbf -gt 0 && XC=9
exit $XC
