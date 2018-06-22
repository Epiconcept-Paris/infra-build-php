#
#	pearman.sh - Install PEAR manpages
#
Tgz=$Bld/files/PEAR_Manpages-*.tgz
Dir=`basename $Tgz .tgz`
tar xf $Tgz -C pear $Dir
mv pear/$Dir pear/man
find pear/man -type f | xargs chmod 644
