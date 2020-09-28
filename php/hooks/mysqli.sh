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
