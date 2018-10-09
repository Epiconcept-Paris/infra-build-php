#
#	mysql.sh - Install MySQL shared extension
#
su -c "tar xf $Bld/files/mysql.tar.gz -C ext" $USER
mv ext/pecl-database-mysql-master ext/mysql	# For mysql.patch
su -c "patch -p0 <$Bld/files/mysql.patch" $USER | sed 's/^p/P/'	# sed for cosmetics
Show="MySQL(shared)"
Opt="--with-mysql=shared"
