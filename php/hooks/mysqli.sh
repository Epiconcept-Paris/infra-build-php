#
#	mysqli.sh - Adapt mysqli extension to MariaDB
#
Bin=/usr/bin
Cfg=mariadb_config
if [ -x $Bin/$Cfg ]; then
    test "$Dbg" && echo "Setting up mysql links to mariadb..."

    Inc=$(expr "$($Cfg --include)" : '-I\([^ ]*\) .*')
    for Hdr in mysql.h mysql_version.h mysql_com.h my_global.h my_config.h my_sys.h
    do
	mv $Inc/$Hdr $Inc/mariadb
    done
    sed -i 's;<my_atomic.h>;<private/my_atomic.h>;' $Inc/server/my_pthread.h
    test -d $Inc/private || ln -s server/private $Inc
    for Hdr in $(cd $Inc/server; echo *.h)
    do
	test -f $Inc/$Hdr || ln -s server/$Hdr $Inc
    done
    test -d $Inc/psi || ln -s server/mysql/psi $Inc
    for Hdr in $(cd $Inc/server/mysql; echo *.h)
    do
	test -f $Inc/$Hdr || ln -s server/mysql/$Hdr $Inc
    done
    for Hdr in $(cd $Inc/mysql; echo *.h)
    do
	test -f $Inc/$Hdr || ln -s mysql/$Hdr $Inc
    done
fi
eval $(mysql --version | sed -nr 's/^.* Distrib ([0-9.]+)(-([^,]+))?, .*$/SQLstr=\1 SQLtag=\3/p')
test "$SQLtag" || SQLtag='MySQL'	# Be defensive (most probably unused)
SQLver=$(NumVer $SQLstr)
if [ '(' $SQLver -ge 100338 -a $SQLver -lt 100500 ')' -o $SQLver -ge 100518 ]; then
    echo "Using --with-pdo-mysql and --with-mysqli without =<path> for $SQLtag $SQLstr"
    PdoMysql=
    MysqlI=
fi
