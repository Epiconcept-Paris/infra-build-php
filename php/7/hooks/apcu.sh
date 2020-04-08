#
#	apcu.sh - Install APCu static extension
#
su -c "tar xf `echo $Bld/files/apcu-*.tgz` -C ext" $USER
mv ext/package.xml ext/apcu-*
Show="APCu"
Opt="--enable-apcu --enable-apc-bc"
