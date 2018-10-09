#
#	APC.sh - Install APC static extension
#
su -c "tar xf `echo $Bld/files/APC-*.tgz` -C ext" $USER
mv ext/APC-* ext/apc	# PHP5's config engine seems to prefer simple dir names
mv ext/package.xml ext/apc
Show="APC"
Opt="--enable-apc"
