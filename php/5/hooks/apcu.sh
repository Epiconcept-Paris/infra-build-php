#
#	apcu.sh - Install APCu static extension
#
tar xf $Bld/files/apcu-*.tgz -C ext
mv ext/apcu-* ext/apcu
mv ext/package.xml ext/apc
Show="APCu"
Opt="--enable-apcu"
