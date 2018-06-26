#
#	mcrypt.sh - Install MCrypt static extension
#
test "$WithMCrypt" && return 0
tar xf $Bld/files/mcrypt-*.tgz -C ext
ExtShow="${ExtShow}MCrypt"
ExtOpts="$ExtOpts--with-mcrypt"
