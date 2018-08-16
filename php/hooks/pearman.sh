#
#	pearman.sh - Install PEAR manpages
#
Tgz=$Bld/files/PEAR_Manpages-*.tgz
Dir=`basename $Tgz .tgz`
su -c "tar xf `echo $Tgz` -C pear $Dir" $USER
mv pear/$Dir pear/man
find pear/man -type f | xargs chmod 644
