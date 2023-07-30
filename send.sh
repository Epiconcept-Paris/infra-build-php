#!/bin/sh
#
#	send.sh - Push packages to files.epiconcept.fr
#
# shellcheck disable=SC2164	# Use 'cd ... || exit'
#
Prg=$(basename "$0")
Dir="$(dirname "$0")"
cd "$Dir"

dist=../php-debs
tmp=/space/tmp/sendphp
usr=epiconcept_build
srv=files.epiconcept.fr

test -d $dist || { echo "$Prg: cannot find '$(realpath $dist)'" >&2; exit 1; }
test "$(id -un)" = 'php' || { echo "$Prg: must run as 'php' user" >&2; exit 1; }

cleanup()
{
    #global Del
    echo "Removing $tmp/"
    rm -rf $tmp
    test "$Del" && sudo bin/defroute del && echo "Deleted default route"
}

trap cleanup 0

#   Setup default route
bin/defroute >/dev/null || {
    sudo -l | grep $PWD/bin/defroute >/dev/null || {
	echo "$Prg: 'sudo bin/defroute' is not configured" >&2
	exit 2;
    }
    sudo bin/defroute add
    echo "Added default route"
    Del=y	# Delete route at exit
}

#   Copy package files
rm -fr $tmp
mkdir $tmp
echo "Preparing package files"
for deb in "$dist"/*/*/*.deb; do
    cp -p "$deb" $tmp/
done

#   Sync files on $srv
#	-r	recursive
#	-l	copy symlinks
#	-t	preserve mtimes
#	-u	update (skip files newer on $srv)
#	-v	verbose
rsync -rltuv $tmp/ $usr@$srv:/space/applisdata/php/ || {
    xc=$?
    echo "$Prg: rsync failed (xc=$xc)" >&2
    exit $xc
}

#   -t:	Force pseudo-terminal alloc
ssh -t $usr@$srv /usr/local/bin/apt_deploy.sh || {
    xc=$?
    echo "$Prg: apt_deploy.sh on '$srv' failed (xc=$xc)" >&2;
    exit $xc
}
