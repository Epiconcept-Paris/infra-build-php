#
#	apcu.sh - Install APCu static extension
#
tar xf $Bld/files/apcu-*.tgz -C ext
mv ext/apcu-* ext/apcu	# PHP5's config engine seems to prefer simple dir names
mv ext/package.xml ext/apc
Show="APCu"
Opt="--enable-apcu"
