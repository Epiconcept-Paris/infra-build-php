#
#	files.sh - Install old .deb packages and patches for PHP 5.2/5.6
#
if ls $Bld/files/*.deb >/dev/null 2>&1; then
    test "$Dbg" && echo "Installing extra .deb packages"
    dpkg -i $Bld/files/*.deb >$Logs/dpkg-i_build.out
    chown $Own $Logs/dpkg-i_build.out
fi
for f in $Bld/files/*.patch
do
    test "$Dbg" && echo "Applying `basename $f`"
    echo "----- `basename $f` -----" >>$Logs/patch.out
    patch -p1 <$f >>$Logs/patch.out
done
chown $Own $Logs/patch.out
