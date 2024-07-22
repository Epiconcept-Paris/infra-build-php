#
#	files.sh - Install old .deb packages and patches for PHP 5.2/5.6
#
debLst="$Bld/files/lenny-debs"
debLog="$Logs/dpkg-i_build.out"
if [ -f $debLst ]; then
    test "$Dbg" && echo "Installing lenny mysql-dev packages"
    (cd $(dirname $debLst); dpkg -i $(sed -nr 's;^ .*/(.*)$;\1.deb;p' $(basename $debLst)) >>$debLog)
    chown $Own $debLog
fi
for f in $Bld/files/*.patch
do
    test -s "$f" || break	# No patch file (f='*.patch')
    Patch 1 $f
done
for f in $Bld/files/*.phar
do
    test -s "$f" || break	# No phar file (f='*.phar')
    cp -p $f ext/phar/tests
done
