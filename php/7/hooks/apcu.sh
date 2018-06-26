#
#	apcu.sh - Install APCu static extension
#
tar xf $Bld/files/apcu-*.tgz -C ext
ExtShow="${ExtShow}APCu"
ExtOpts="$ExtOpts--enable-apcu"
