#
#	fileinfo.sh - Install Fileinfo static extension
#
#  GNU tar complains that Fileinfo-1.0.4.tgz is missing 512 NULs: add them
su -c "(gunzip <`echo $Bld/files/Fileinfo-*.tgz`; printf '\0' | dd conv=sync status=none) | tar xf - -C ext" $USER
mv ext/Fileinfo-* ext/fileinfo	# PHP's config engine seems to prefer simple dir names
mv ext/package.xml ext/fileinfo
Show="FileInfo"
Opt="--with-fileinfo"
