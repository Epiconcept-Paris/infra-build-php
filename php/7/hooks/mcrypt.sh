#
#	mcrypt.sh - Install MCrypt static extension
#
echo "$ExtOpts" | grep -- '--with-mcrypt ' >/dev/null && return 0
su -c "tar xf `echo $Bld/files/mcrypt-*.tgz` -C ext" $USER
mv ext/package.xml ext/mcrypt-*
Show="MCrypt"
Opt="--with-mcrypt"
