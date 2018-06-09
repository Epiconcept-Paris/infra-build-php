#!
#	apcu.sh - Install APCu static extension
#
tar xf $Bld/files/apcu-*.tgz -C ext
#cp -p configure $Dist/configure0
./buildconf --force >$Dist/buildconf.out
#cp -p configure $Dist
test "$ExtOpts" && ExtOpts="$ExtOpts "
ExtOpts="$ExtOpts--enable-apcu"
