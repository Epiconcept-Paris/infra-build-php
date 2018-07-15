#
#	APC.sh - Install APC static extension
#
tar xf $Bld/files/APC-*.tgz -C ext
mv ext/APC-* ext/apc	# PHP's config engine seems to prefer simple dir names
mv ext/package.xml ext/apc
Show="APC"
Opt="--enable-apc"
