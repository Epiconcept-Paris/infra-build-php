#
#	oauth.sh - Install OAuth static extension
#
su -c "tar xf `echo $Bld/files/oauth-*.tgz` -C ext" $USER
mv ext/oauth-* ext/oauth	# PHP5's config engine seems to prefer simple dir names
mv ext/package.xml ext/oauth
Show="OAuth"
Opt="--enable-oauth"
