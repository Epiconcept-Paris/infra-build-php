#
#	files.sh - Install patches for PHP 7.4
#
for f in $Bld/files/deb/*.patch
do
    test -s "$f" || break	# No patch file (f ends with '/*.patch')
    Patch 1 $f
done
