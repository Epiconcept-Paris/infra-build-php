#!/bin/sh
#
#	savedist.sh - Save prod versions in '../php-debs' side directory
#
# shellcheck disable=SC2164	# Use 'cd ... || exit'
#
Usr=$(id -un)
Prg="$(basename "$0")"
Dir="$(dirname "$0")"
cd "$Dir"

DebDir='../php-debs'
NoDir="$Prg: cannot find directory"

test "$*" && echo "NOTE: arguments '$*' to $Prg will be ignored" >&2
test "$Usr" = 'php' || { echo "$Prg: for the 'php' user only" >&2; exit 1; }
test -d 'debian' || { echo "$NoDir 'debian' in '$PWD'" >&2; exit 1; }

#   Test below assumes 'php-prod' and 'infra-build-php' are not in the same dir
test -d "$DebDir" || { echo "$NoDir '$(basename "$DebDir")' in '$(dirname "$PWD")'" >&2; exit 1; }

for dv in $(cd 'debian'; echo [0-9] [0-9][0-9])
do
    for d in "debian/$dv/dist"/* "debian/$dv/multi"
    do
	test -d "$d" || continue	# Skip if pattern does not exist
	pv=$(basename "$d")
	if [ -d "$DebDir/$dv/$pv" ]; then
	    bad=
	    case "$pv" in
		[5-9].*)    test -f "$d"/epi-php-*-cli_*.deb || bad=y;;
		tools)	    test -f "$d"/epi-tools-waitpid_*.deb || bad=y;;
		multi)	    test -d "$d"/pkgs -a -d "$d"/logs || bad=y;;
	    esac
	    test "$bad" && { echo "Skipping $d (incomplete build)" >&2; continue; }
	    diff=
	    for f in $(find "$d" -type f | sed "s;^$d/;;")
	    do
		cmp "$d/$f" "$DebDir/$dv/$pv/$f" >/dev/null 2>&1 || { diff='y'; break; }
	    done
	    test "$diff" && echo "Dist $d differs from $DebDir/$dv/$pv - rename/delete that if needed" || echo "Dist $d is already saved"
	else
	    echo "Saving $d"
	    if [ "$pv" = 'multi' ]; then
		tar Ccf "debian/$dv" - "$pv" | tar Cxf "$DebDir/$dv" -
	    else
		tar Ccf "debian/$dv/dist" - "$pv" | tar Cxf "$DebDir/$dv" -
	    fi
	fi
    done
done
