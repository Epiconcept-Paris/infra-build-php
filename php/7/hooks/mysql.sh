#
#	mysql.sh - Install MySQL shared extension
#
su -c "tar xf $Bld/files/mysql.tar.gz -C ext" $USER
mv ext/pecl-database-mysql-master ext/mysql	# For mysql.patch
Patch 0 "$Bld/files/mysql.patch"
Show="MySQL(shared)"
Opt="--with-mysql=shared"
