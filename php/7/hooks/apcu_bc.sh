#
#	apcu.sh - Install APCu_bc static extension
#
su -c "tar xf `echo $Bld/files/apcu_bc-*.tgz` -C ext" $USER
mv ext/package.xml ext/apc_bc-*
Show="APC"
Opt="--enable-apc"
