#!/bin/sh
#
#	send.sh - Push packages to the APT-repo host
#
# shellcheck disable=SC2164	# Use 'cd ... || exit'
#
Prg=$(basename "$0")
Dir="$(dirname "$0")"
cd "$Dir"

Usr='php'
Bin='/usr/local/bin'
Bah='bin/apthost'
test "$(id -un)" = $Usr || { echo "$Prg: must run as the '$Usr' user" >&2; exit 1; }
test -x $Bin/defroute || { echo "$Prg: cannot find the 'defroute' script in '$Bin'" >&2; exit 1; }
test -x $Bah || { echo "$Prg: cannot find the '$Bah' script in '$PWD'" >&2; exit 1; }
Srv=$($Bah) || exit $?

dist=../php-debs
tmp=/space/tmp/sendphp

test -d $dist || { echo "$Prg: cannot find '$(realpath $dist)'" >&2; exit 1; }

cleanup()
{
    #global Del
    echo "Removing $tmp/"
    rm -rf $tmp
    test "$Del" && sudo $Bin/defroute del && echo "Deleted default route"
}

trap cleanup 0

#   Setup default route
$Bin/defroute >/dev/null || {
    sudo -l | grep $Bin/defroute >/dev/null || {
	echo "$Prg: 'sudo $Bin/defroute' is not configured" >&2
	exit 2;
    }
    sudo $Bin/defroute add
    echo "Added default route"
    Del=y	# Delete route at exit
}

#   Copy package files
rm -fr $tmp
mkdir $tmp
echo "Preparing package files"
for deb in "$dist"/*/*/*.deb; do
    test -f "$deb" || break
    cp -p "$deb" $tmp/
done

#   Sync files on $Srv
#	-r	recursive
#	-l	copy symlinks
#	-t	preserve mtimes
#	-u	update (skip files newer on $Srv)
#	-v	verbose
rsync -rltuv $tmp/ $Srv:/space/applisdata/php/ || {
    xc=$?
    echo "$Prg: rsync failed (xc=$xc)" >&2
    exit $xc
}

ssh $Srv /usr/local/bin/apt_deploy.sh || {
    xc=$?
    echo "$Prg: apt_deploy.sh on '$Srv' failed (xc=$xc)" >&2;
    exit $xc
}
