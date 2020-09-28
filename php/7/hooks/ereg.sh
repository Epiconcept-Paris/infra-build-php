#
#	ereg.sh - Install ereg legacy extension
#
test -d ext/ereg && { test "$Dbg" && echo "Extension ereg is native"; return 0; }
su -c "tar xf $Bld/files/ereg.tar.gz -C ext" $USER
mv ext/pecl-text-ereg-master ext/ereg	# Required by the extension's code!
Show="ereg"
Opt="--with-regex"
