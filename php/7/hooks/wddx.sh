#
#	wddx.sh - Install wddx legacy extension
#
test -d ext/wddx && { test "$Dbg" && echo "Extension wddx is native"; return 0; }
su -c "tar xf $Bld/files/wddx.tar.gz -C ext" $USER
mv ext/pecl-text-wddx-master ext/wddx	# Required by the extension's code!
Show="wddx"
Opt="--enable-wddx"
