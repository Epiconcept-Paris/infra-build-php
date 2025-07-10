#
#	files.sh - Install patches for PHP 7.4
#
CVEtgz=$Bld/files/deb-CVE.tgz
CVEdir=$(expr "$CVEtgz" : '\(.*\)\.tgz$')
if [ -f $CVEtgz ]; then
    tar xCf $(dirname $CVEtgz) $CVEtgz
    sed "s;^;$CVEdir/;" $CVEdir/series | while read f
    do
	Patch 1 $f
    done
fi
