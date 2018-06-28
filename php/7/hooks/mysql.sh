#
#	mysql.sh - Install MySQL shared extension
#
tar xf $Bld/files/mysql.tgz -C ext
mv ext/pecl-database-mysql-master ext/mysql
patch -p0 <$Bld/files/mysql.patch | sed 's/^p/P/'	# sed for cosmetics
Show="MySQL(shared)"
Opt="--with-mysql=shared"
