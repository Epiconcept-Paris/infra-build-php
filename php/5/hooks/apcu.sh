#
#	apcu.sh - Install APCu static extension
#
su -c "tar xf `echo $Bld/files/apcu-*.tgz` -C ext" $USER
mv ext/apcu-* ext/apcu	# PHP5's config engine seems to prefer simple dir names
mv ext/package.xml ext/apc
Show="APCu"
Opt="--enable-apcu"
