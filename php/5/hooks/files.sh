#!/bin/sh
#
#	files.sh - Install old .deb packages and patches for PHP 5.2-
#
dpkg -i $Bld/files/*.deb >$Logs/dpkg-i_build.out
for f in $Bld/files/*.patch
do
    test "$Dbg" && echo "Applying `basename $f`"
    echo "----- `basename $f` -----" >>$Logs/patch.out
    patch -p1 <$f >>$Logs/patch.out
done
