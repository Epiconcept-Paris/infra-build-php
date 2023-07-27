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

cleanup()
{
    echo "Deleting $tmp/"
    rm -rf $tmp
}

rm -fr $tmp
mkdir $tmp
for deb in "$dist"/*/*/*.deb; do
    cp -p "$deb" $tmp/
done
trap cleanup 0

rsync -rltuv $tmp/ $usr@$srv:/space/applisdata/php/ || {
    xc=$?
    echo "$Prg: rsync failed (xc=$xc)" >&2
    exit $xc
}

ssh -t $usr@$srv /usr/local/bin/apt_deploy.sh || {
    xc=$?
    echo "$Prg: apt_deploy.sh on '$srv' failed (xc=$xc)" >&2;
    exit $xc
}
