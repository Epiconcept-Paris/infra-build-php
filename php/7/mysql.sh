#
#	mysql.sh - Install MySQL shared extension
#
tar xf $Bld/files/mysql.tgz -C ext
mv ext/pecl-database-mysql-master ext/mysql
ExtShow="${ExtShow}MySQL(shared)"
ExtOpts="$ExtOpts--with-mysql=shared"
