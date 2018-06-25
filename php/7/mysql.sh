#
#	mysql.sh - Install MySQL shared extension
#
tar xf $Bld/files/mysql.tgz -C ext
sed -e '743,745d' -i ext/pecl-database-mysql-master/php_mysql.c
mv ext/pecl-database-mysql-master ext/mysql
ExtShow="${ExtShow}MySQL(shared)"
ExtOpts="$ExtOpts--with-mysql=shared"
