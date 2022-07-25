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
if ls $Bld/files/*.patch >/dev/null 2>&1; then
    >$Logs/patch.out
    for f in $Bld/files/*.patch
    do
	test "$Dbg" && echo "Applying `basename $f`"
	echo "----- `basename $f` -----" >>$Logs/patch.out
	patch -p1 <$f >>$Logs/patch.out
    done
    chown $Own $Logs/patch.out
fi
