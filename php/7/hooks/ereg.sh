#
#	ereg.sh - Install ereg legacy extension
#
su -c "tar xf $Bld/files/ereg.tgz -C ext" $USER
mv ext/ereg-* ext/ereg
Show="ereg"
Opt="--with-regex"
