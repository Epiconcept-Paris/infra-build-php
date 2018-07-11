#
#	mcrypt.sh - Install MCrypt static extension
#
echo "$ExtOpts" | grep -- '--with-mcrypt ' >/dev/null && return 0
tar xf $Bld/files/mcrypt-*.tgz -C ext
Show="MCrypt"
Opt="--with-mcrypt"
