#
#	ereg.sh - Install ereg legacy extension
#
su -c "tar xf $Bld/files/ereg.tar.gz -C ext" $USER
mv ext/pecl-text-ereg-master ext/ereg
Show="ereg"
Opt="--with-regex"
