#
#	oauth.sh - Install OAuth static extension
#
su -c "tar xf `echo $Bld/files/oauth-*.tgz` -C ext" $USER
Show="OAuth"
Opt="--enable-oauth"
