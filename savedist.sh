#!/bin/sh

Prg="$(basename "$0")"
DebDir='../php-debs'
test -d "$DebDir" -a -d 'debian' || { echo "$Prg: for php-prod builds only" >&2; exit 1; }
for dv in 8 9 10 11
do
    for d in "debian/$dv/dist"/*
    do
	test -d "$d" || break
	pv=$(basename $d)
	if [ -d "$DebDir/$dv/$pv" ]; then
	    diff=
	    for f in $(find $d -type f | sed "s;^$d/;;")
	    do
		cmp "$d/$f" "$DebDir/$dv/$pv/$f" >/dev/null 2>&1 || { diff='y'; break; }
	    done
	    test "$diff" && echo "$DebDir/$dv/$pv exists - rename it if needed" || echo "Skipping $d (already saved)"
	else
	    echo "Saving $d"
	    tar Ccf "debian/$dv/dist" - "$pv" | tar Cxf "$DebDir/$dv" -
	fi
    done
done
