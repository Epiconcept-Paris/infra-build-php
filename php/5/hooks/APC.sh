#
#	APC.sh - Install APC static extension
#
tar xf $Bld/files/APC-*.tgz -C ext
mv ext/APC-* ext/apc
mv ext/package.xml ext/apc
export PHP_AUTOCONF='/usr/bin/autoconf2.13'
Show="APC"
Opt="--enable-apc"
