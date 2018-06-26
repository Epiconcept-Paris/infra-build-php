#
#	oauth.sh - Install OAuth static extension
#
tar xf $Bld/files/oauth-*.tgz -C ext
ExtShow="${ExtShow}OAuth"
ExtOpts="$ExtOpts--enable-oauth"
