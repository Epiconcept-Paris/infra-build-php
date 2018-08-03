#
#	apcu.sh - Install APCu static extension
#
su -c "tar xf `echo $Bld/files/apcu-*.tgz` -C ext" $USER
Show="APCu"
Opt="--enable-apcu"
