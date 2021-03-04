#
#	ssh2.sh - Install SSH2 shared extension
#
su -c "tar xf $Bld/files/ssh2-*.tgz -C ext" $USER
Show="SSH2"
Opt="--with-ssh2"
