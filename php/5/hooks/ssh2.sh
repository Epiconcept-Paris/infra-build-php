#
#	ssh2.sh - Install SSH2 shared extension
#
su -c "tar xf $Bld/files/ssh2-*.tgz -C ext" $USER
rm -rf /usr/src/php/ext/ssh2
mv /usr/src/php/ext/ssh2-* /usr/src/php/ext/ssh2
Show="SSH2"
Opt="--with-ssh2"
