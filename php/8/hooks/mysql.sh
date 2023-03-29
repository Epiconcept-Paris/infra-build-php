#
#	mysql.sh - Install MySQL shared extension
#
su -c "tar xf $Bld/files/mysql.tar.gz -C ext" $USER
mv ext/pecl-database-mysql-master ext/mysql	# For mysql.patch
Patch 0 "$Bld/files/mysql.patch"
Patch 0 "$Bld/files/mysqlnd.patch"
Show="MySQL(shared)"
Opt="--with-mysql=shared"
PdoMysql=
MysqlI=
if VerCmp $Ver -lt '8.1.17'; then
    PdoMysql='=/usr'
    MysqlI='=/usr/bin/mysql_config'
fi
