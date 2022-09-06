#
#	mcrypt.sh - Install MCrypt static extension (if needed)
#		    Apply mcrypt.patch to remove DEPRECATED warnings
#
echo "$ExtOpts" | grep -- '--with-mcrypt ' >/dev/null || {
    su -c "tar xf `echo $Bld/files/mcrypt-*.tgz` -C ext" $USER
    mv ext/mcrypt-* ext/mcrypt
    mv ext/package.xml ext/mcrypt
    Opt="--with-mcrypt"
    Show="MCrypt"
}
#   Apply patch even though extension is native to 7.x
Patch 0 "$Bld/files/mcrypt.patch"
